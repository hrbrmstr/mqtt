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
#' been received.
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

#' Subscribe to an MQTT Topic
#'
#' @md
#' @param host,port host (character) and port (integer) to connect to. Defaults to
#'        "`test.mosquitto.org`".
#' @param client_id the client id to use. Defaults to "`r_mqtt`".
#' @param topic topic to subscribe to. Defaults to wildcard "`#`"
#' @param keepalive the number of seconds after which the broker should send a PING
#'        message to the client if no other messages have been exchanged in that time.
#'        Defaults to `60`
#' @param qos integer value `0`, `1` or `2` indicating the Quality of Service to be used for
#'        the message.
#' @export
topic_subscribe <- function(host="test.mosquitto.org", port=1883L,
                            client_id="r_mqtt", topic="#",
                            keepalive=60L, qos=0L,
                            message_callback=mqtt_default_message_callback,
                            connection_callback=mqtt_default_connection_callback) {

  subscribe_(
    host, as.integer(port), as.integer(keepalive), client_id, topic, as.integer(qos),
    connection_callback, message_callback
  )

}
# void subscribe_(
#     std::string host, int port, int keepalive,
#     std::string client_id, std::string topic, int qos,
#     Rcpp::Function connection_cb, Rcpp::Function message_cb
#   ) {