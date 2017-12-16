library(mqtt)

silent_log_cb <- function(lvl, msg) { }

mm <- MQTT$mqtt_r

x <- new(mm, "hrbrmstr-0123", "test.mosquitto.org", 1883L)

x$set_log_cb(silent_log_cb)

# x$subscribe(0, "bbc/subtitles/bbc_news24/raw", 0)
x$subscribe(0, "#", 0)

n <- 1000
msgs <- list()

idx <- 0

collector <- function(id, topic, payload, qos, retain) {
  if (grepl("TAMK|energy", topic)) return()
  idx <<- idx + 1
  msgs <<- c(msgs, list(list(id=id, topic=topic, payload=list(payload))))
}

x$set_message_cb(collector)

while(idx < n) {
  x$loop(5, 1)
}

xdf <- dplyr::bind_rows(msgs)
xdf

x$disconnect()

rm(x)
rm(xdf)

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

    for (.cb in .callbacks) {
      .cb(id, topic, payload, qos, retain)
    }

  }

}

mqtt_run <- function(mob, times=10000) {

  .mqtt <- MQTT$mqtt_r
  .svr <- new(.mqtt, mobj$client_id, mobj$host, mobj$port)

  .svr$set_message_cb(mk_msg_cb_handler(mobj$subscriptions))

  mobj$mqtt_objs <- list(.mqtt=.mqtt, .svr=.svr)

  idx <- 0;
  n <- times
  while(idx < n) {
    .svr$loop(5, 1)
  }

  mobj

}





