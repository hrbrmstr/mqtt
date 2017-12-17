#' Provide broker connection setup information
#'
#' @param client_id your client id (must be unique)
#' @param host broker host/IP
#' @param port broker port
#' @return mqtt objec
#' @export
mqtt_broker <- function(client_id, host="test.mosquitto.org", port=1883L) {

  list(
    client_id = client_id,
    host = host,
    port = port,
    username = NULL,
    password = NULL,
    silent = c(),
    subscriptions = list()
  ) -> mobj

  invisible(mobj)

}

#' Set username & passwords for the connection
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param username,password auto pulled from the environment (`MQTT_USERNAME`, `MQTT_PASSWORD`)
#'        or specify manually.
#' @return `mobj`
#' @export
mqtt_username_pw <- function(mobj, username=Sys.getenv("MQTT_USERNAME"),
                             password=Sys.getenv("MQTT_PASSWORD")) {

  mobj$username <- username
  mobj$password <- password

  invisible(mobj)

}

#' Subscribe to a channel identifying a callback
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param topic to subscribe to
#' @param qos 0:3
#' @param callback your callback function (must have a signature consisting
#'        of these parameters: `id`, `topic`, `payload`, `qos`, `retain`, `con`) and you should
#'        ideally test `topic` in your function to ensure it is the one you should
#'        be responding to. `con` provodes direct access to internal object methods.
#'        So, for example, you can run `con$publish(...)` inside a message callback
#'        handler to publish your own data based on what you received from the broker.
#' @return `mobj`
#' @export
mqtt_subscribe <- function(mobj, topic, callback, qos=0) {

  mobj$subscriptions <- c(mobj$subscriptions, list(list(topic = topic, qos = qos, callback = callback)))
  invisible(mobj)

}

as_message_callback <- function(x, env = rlang::caller_env()) {
  rlang::coerce_type(
    x, rlang::friendly_type("function"),
                     closure = {
                       x
                     },
                     formula = {
                       if (length(x) > 2) rlang::abort("Can't convert a two-sided formula to an mqtt message callback function")
                       f <- function() { x }
                       formals(f) <- alist(id=, topic=, payload=, qos=, retain=, con=)
                       body(f) <- rlang::f_rhs(x)
                       f
                     }
  )
}

mk_msg_cb_handler <- function(.subs, .svr) {

  .callbacks <- lapply(.subs, function(.x) .x$callback)
  .callbacks <- lapply(.callbacks, as_message_callback)

  con <- .svr

  function(id, topic, payload, qos, retain) {

    sapply(.callbacks, function(.cb) {
      .cb(id, topic, payload, qos, retain, con)
    }) -> ret_vals

  }

}

#' Silence log and/or error or more callbacks
#'
#' For the moment, MQTT objects are initialized with very verbose `message()`ing since
#' this is an early-stage development package using a C++ threaded library. If you
#' don't want to see too many verbose debug messages, you can use this function to
#' quite things down a bit. For the time being, initial connection messages will
#' not be silenced.
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param callbacks any/all of "`connect`", "`disconnect`", "`error`", "`log`", "`publish`",
#'       "`subscribe`". If "`all`", then all silence-able callbacks will be silenced.
#' @export
mqtt_silence <- function(mobj, callbacks=c("error", "log", "publish")) {

  allowed_callbacks = c("all", "connect", "disconnect", "error", "log", "publish", "subscribe")

  mobj$silent <- c(mobj$silent, unlist(callbacks, use.names = FALSE))
  mobj$silent <- unique(sort(mobj$silent))
  mobj$silent <- mobj$silent[mobj$silent %in% allowed_callbacks]

  invisible(mobj)

}

.will_fall <- function(.svr, quiet_things) {

  if ("all" %in% quiet_things) {
    .svr$set_log_cb(mqtt_silent_callback)
    .svr$set_error_cb(mqtt_silent_callback)
    .svr$set_publish_cb(mqtt_silent_callback)
    .svr$set_subscribe_cb(mqtt_silent_callback)
    .svr$set_discconn_cb(mqtt_silent_callback)
    .svr$set_connection_cb(mqtt_silent_callback)
  } else {
    for (.quiet in quiet_things) {
      if (.quiet ==  "log") .svr$set_log_cb(mqtt_silent_callback)
      if (.quiet ==  "error") .svr$set_error_cb(mqtt_silent_callback)
      if (.quiet ==  "publish") .svr$set_publish_cb(mqtt_silent_callback)
      if (.quiet ==  "subscribe") .svr$set_subscribe_cb(mqtt_silent_callback)
      if (.quiet ==  "disconnect") .svr$set_discconn_cb(mqtt_silent_callback)
      if (.quiet ==  "connect") .svr$set_connection_cb(mqtt_silent_callback)
    }
  }

}

#' Run an MQTT event loop
#'
#' This will provide an event loop that will run `time` number of times or forever (until
#' a signal is received or the program is terminated).
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param times if `Inf` then run forever, otherwise a positive value which will be executed
#'        this many time. This value is trackes for **all** MQTT exchanges, not just messages.
#' @param timeout Maximum number of milliseconds to wait for network activity before timing out.
#'        Set to 0 for instant return.  Set negative to use the default of `1000` ms.
#' @param max_packets is here for potential forward compatibility but internally it will
#'        be reset to 1.
#' @return `mobj`
#' @export
mqtt_run <- function(mobj, times=10000, timeout=1000, max_packets=1) {

  max_packets <- 1
  .mqtt <- MQTT$mqtt_r

  if (is.null(mobj$username)) {
    .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port)
  } else {
    .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port, mobj$username, mobj$password)
  }

  .will_fall(.svr, mobj$silent)

  for (.sub in mobj$subscriptions) {
    message(sprintf("Subscribing to %s", .sub$topic))
    .svr$subscribe(0, .sub$topic, .sub$qos)
  }

  #   .svr$set_publish_cb(mqtt_silent_connection_callback)

  .svr$set_message_cb(mk_msg_cb_handler(mobj$subscriptions, .svr))

  mobj$mqtt_objs <- list(.mqtt=.mqtt, .svr=.svr)

  idx <- 0;
  n <- times
  while(idx < n) {
    rc <- .svr$loop(timeout, max_packets)
    if (rc != 0) .svr$reconnect()
  }

  .svr$disconnect()

  rm(.svr)
  rm(.mqtt)

  invisible(mobj)

}

#' Initiate an MQTT connection
#'
#' This will initiate a connection to an MQTT broker. You are responsible for saving
#' the returned object and calling `mqtt_end()` on it to cleanly free up resources.
#' You are also responsible for managing your own event loop (using `mqtt_loop()`).
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @return `mobj`
#' @export
mqtt_begin <- function(mobj) {

  .mqtt <- MQTT$mqtt_r

  if (is.null(mobj$username)) {
    .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port)
  } else {
    .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port, mobj$username, mobj$password)
  }

  .will_fall(.svr, mobj$silent)

  for (.sub in mobj$subscriptions) {
    message(sprintf("Subscribing to %s", .sub$topic))
    .svr$subscribe(0, .sub$topic, .sub$qos)
  }

  #   .svr$set_publish_cb(mqtt_silent_connection_callback)

  .svr$set_message_cb(mk_msg_cb_handler(mobj$subscriptions, .svr))

  mobj$mqtt_objs <- list(.mqtt=.mqtt, .svr=.svr)

  invisible(mobj)

}

#' Run an mqtt loop iteration
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @return `mobj`
#' @param timeout Maximum number of milliseconds to wait for network activity before timing out.
#'        Set to 0 for instant return.  Set negative to use the default of `1000` ms.
#' @param max_packets is here for potential forward compatibility but internally it will
#'        be reset to 1.
#' @export
mqtt_loop <- function(mobj, timeout=1000, max_packets=1) {
  max_packets <- 1
  while(mobj$mqtt_objs$.svr$loop(timeout, max_packets) != 0) mobj$mqtt_objs$.svr$reconnect()
  invisible(mobj)
}

#' Close an MQTT connection
#'
#' You need to use this if you used `mqtt_begin()`
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @return `mobj`
#' @export
mqtt_end <- function(mobj) {

  mobj$mqtt_objs$.svr$disconnect()

  mobj$mqtt_objs$.svr <- NULL
  mobj$mqtt_objs$.mqtt <- NULL
  mobj$mqtt_objs <- NULL

  invisible(mobj)

}