library(mqtt)

silent_cb <- function(...) { }

mm <- MQTT$mqtt_r
x <- new(mm, "me", "test.mosquitto.org", 1883L)

x$set_log_cb(silent_cb)

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
