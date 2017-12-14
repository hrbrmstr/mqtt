#' mqtt silent connection callback function (does nothing)
#'
#' @param result the return code of the connection response (ignored)
#' @export
mqtt_silent_connection_callback <- function(result) {}

#' mqtt default connection callback function
#'
#' This will be set by default if no parameter is specified to
#' connection functions. If you use your own function, it should
#' be modeled after this one (i.e. take the same function signature).
#'
#' @param result the return code of the connection response, one of:
#' - `0`: success
#' - `1` : connection refused (unacceptable protocol version)
#' - `2` : connection refused (identifier rejected)
#' - `3` : connection refused (broker unavailable)
#' - `4-255` : reserved for future use
#' @export
mqtt_default_connection_callback <- function(result) {
  message(sprintf("Default connect callback result: %s", result))
}

.def_msg_max <- 50
.def_msg_count <- 0

#' mqtt default message callback function
#'
#' This will be set by default if no parameter is specified to
#' connection functions. If you use your own function, it should
#' be modeled after this one (i.e. take the same function signature).\cr
#' \cr
#' This default function will display messages and quit after 50 messages have
#' been received.\cr
#' \cr
#' You **must** return a character value (an empty string --- "" --- is fine) from
#' your callback function.
#'
#' @section Special Functionality:
#' If a message callback function returns the string "`quit`", then the MQTT
#' connection will be closed. This makes it possible to subscribe to a topic,
#' keep track of messages and stop processing when a known message is received
#' or after a certain number of messages (you need to keep track of the latter
#' yourself).
#'
#' @param id the message id
#' @param topic the message topic
#' @param payload the message payload (raw)
#' @param qos the effective qos for the message
#' @param retain is this message marked as "retain"?
mqtt_default_message_callback <- function(id, topic, payload, qos, retain) {
  .def_msg_count <<- .def_msg_count + 1
  message(readBin(payload, "character"))
  return(if (.def_msg_count == .def_msg_max) "quit" else "continue")
}
