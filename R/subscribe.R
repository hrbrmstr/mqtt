#' Subscribe to an MQTT Topic
#'
#' See [mqtt_default_connection_callback()] and [mqtt_default_message_callback()]
#' for more information on callbacks
#'
#' @section Topics:
#' A topic is a UTF-8 string used by the broker to filter messages for
#' subscription. They consist of one or more topic levels. Each level is separated
#' by a forward slash --- `/` --- (a.k.a. the topic level separator). They topic
#' components can contain spaces.\cr
#' \cr
#' Topics can have wildcards. For the moment, you can visit the
#' [official documentation section](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718106)
#' on specifying topics. Similar examples will eventually be in a vignette.
#'
#' @md
#' @note TODO authentication & encryption support
#' @param host,port host (character) and port (integer) to connect to. Defaults to
#'        "`test.mosquitto.org`".
#' @param client_id the client id to use. **Max 23 characters**. **Must be unique**.
#'        Defaults to "`r_mqtt`" + a random string.
#' @param topic topic to subscribe to. Defaults to wildcard "`#`"
#' @param keepalive the number of seconds after which the broker should send a PING
#'        message to the client if no other messages have been exchanged in that time.
#'        Defaults to `60`
#' @param qos integer value `0`, `1` or `2` indicating the Quality of Service to be used for
#'        the message.
#' @param message_callback your R worker function for messages. See [mqtt_default_connection_callback()]
#'        for more details on how to write your own. That one is the default.
#' @param connection_callback you can use the package-provided [mqtt_silent_connection_callback()]
#'        if you do not want any message printed at startup. It defaults
#'        to using a package-provided [mqtt_default_connection_callback()] which
#'        will use `message()` to print out a one-line diagnostic message.
#' @param disconnect_callback called when the connection is disconnecting
#' @export
topic_subscribe <- function(host="test.mosquitto.org", port=1883L,
                            client_id=sprintf("mqtt_r_%s", uuid::UUIDgenerate()),
                            topic="#",
                            keepalive=60L, qos=0L,
                            message_callback=mqtt_default_message_callback,
                            connection_callback=mqtt_default_connection_callback,
                            disconnect_callback=mqtt_default_disconnection_callback) {

  client_id <- substr(client_id, 1, 23)

  subscribe_(
    host = host, port = as.integer(port), keepalive = as.integer(keepalive),
    client_id = client_id, topic = topic, qos = as.integer(qos),
    connection_cb = connection_callback,
    message_cb = message_callback,
    disconnect_cb = disconnect_callback
  )

}
