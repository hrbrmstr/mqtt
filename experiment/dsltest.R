library(mqtt)
library(magrittr)

# dsl ---------------------------------------------------------------------

mqtt_broker <- function(client_id, host="test.mosquitto.org", port=1883L) {
  list(
    client_id = client_id,
    host = host,
    port = port,
    subscriptions = list()
  )
}

mqtt_subscribe <- function(mobj, topic, callback, qos=0) {

  mobj$subscriptions <- c(mobj$subscriptions, list(list(topic = topic, qos = qos, callback = callback)))
  mobj

}

mk_msg_cb_handler <- function(.subs) {

  .callbacks <- lapply(.subs, function(.x) .x$callback)

  function(id, topic, payload, qos, retain) {

    sapply(.callbacks, function(.cb) {
      .cb(id, topic, payload, qos, retain)
    }) -> ret_vals

  }

}

mqtt_run <- function(mobj, times=10000) {

  .mqtt <- MQTT$mqtt_r
  .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port)

  for (.sub in mobj$subscriptions) {
    message(sprintf("Subscribing to %s", .sub$topic))
    .svr$subscribe(0, .sub$topic, .sub$qos)
  }

  .svr$set_log_cb(mqtt_silent_connection_callback)
  .svr$set_publish_cb(mqtt_silent_connection_callback)

  .svr$set_message_cb(mk_msg_cb_handler(mobj$subscriptions))

  mobj$mqtt_objs <- list(.mqtt=.mqtt, .svr=.svr)

  idx <- 0;
  n <- times
  while(idx < n) {
    .svr$loop(5, 1)
  }

  .svr$disconnect()

  rm(.svr)
  rm(.mqtt)

  #mobj

}


# test! -------------------------------------------------------------------


mqtt_broker("hrbrtst") %>%
  mqtt_subscribe("bbc/subtitles/bbc_one_london/raw", function(id, topic, payload, qos, retain) {
    if (topic == "bbc/subtitles/bbc_one_london/raw")
      cat(crayon::yellow(topic), crayon::green(readBin(payload, "character")), "\n", sep=" ")
    return("")
  }) %>%
  mqtt_subscribe("bbc/subtitles/bbc_news24/raw", function(id, topic, payload, qos, retain) {
    if (topic == "bbc/subtitles/bbc_news24/raw")
      cat(crayon::yellow(topic), crayon::red(readBin(payload, "character")), "\n", sep=" ")
    return("")
  }) %>%
  mqtt_run() -> x

