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
#' @param username,password auto pulled from the environment (`MQTT_USERNAME`, `MQTT_PASSWORD`)
#'        or specify manually.
#' @return `mobj`
#' @export
mqtt_username_pw <- function(mobj, username=Sys.get("MQTT_USERNAME"),
                             password=Sys.get("MQTT_PASSWORD")) {

  mobj$username <- username
  mobj$password <- password

  invisible(mobj)

}

#' Subscribe to a channel identifying a callback
#'
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param topic to subscribe to
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

as_message_callback <- function(x, env = caller_env()) {
  rlang::coerce_type(x, friendly_type("function"),
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
#' @param mobj an mqtt object created with `mqtt_broker()` or augmented by other functions
#' @param callbacks any/all of "`error`","`log`", or "`publish`".
#' @export
mqtt_silence <- function(mobj, callbacks=c("error", "log", "publish")) {

  allowed_callbacks = c("error", "log", "publish")

  mobj$silent <- c(mobj$silent, unlist(callbacks, use.names = FALSE))
  mobj$silent <- unique(sort(mobj$silent))
  mobj$silent <- mobj$silent[mobj$silent %in% allowed_callbacks]

  invisible(mobj)

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

  for (.quiet in mobj$silent) {
    if (.quiet ==  "log") .svr$set_log_cb(mqtt_silent_callback)
    if (.quiet ==  "error") .svr$set_error_cb(mqtt_silent_connection_callback)
    if (.quiet ==  "publish") .svr$set_publish_cb(mqtt_silent_connection_callback)
  }

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