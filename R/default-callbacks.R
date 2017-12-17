.mqtt_default_cb <- function(...) { # noop
}

.mqtt_connect_cb <- function(rc) {
  message(sprintf("connect / rc [%s]", rc))
}

.mqtt_disconnect_cb <- function(rc) {
  message(sprintf("disconnect / rc [%s]", rc))
}

.mqtt_publish_cb <- function(mid) {
  message(sprintf("publish / message id [%s]", mid))
}

.mqtt_message_cb <- function(id, topic, payload, qos, retain) {
  pay <- try(readBin(payload, "character"), silent = TRUE)
  try(cat(crayon::green(sprintf("message / id [%s] topic {%s} payload (%s)", id, topic, pay)), "\n", sep=""), silent=TRUE)
}

.mqtt_subscribe_cb <- function(mid, qos_count) {
  message(sprintf("subscribe / mid [%s] qos ct {%s}", mid, qos_count))
}

.mqtt_unsubscribe_cb <- function(mid) {
  message(sprintf("unsubscribe / mid [%s]", mid))
}

.mqtt_log_cb <- function(lvl, msg) {
  message(sprintf("LOG: [%s] %s", lvl, msg))
}

.mqtt_error_cb <- function() {
  message("ERROR")
}
