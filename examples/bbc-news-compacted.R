# watch bbc news 24 live, compacted subtitles meander by

bbc_callback <- function(id, topic, payload, qos, retain) {
  cat(crayon::green(readBin(payload, "character")), "\n", sep="")
  return("") # ctrl-c will terminate
}

mqtt::topic_subscribe(topic = "bbc/subtitles/bbc_news24/compacted",
                      connection_callback=mqtt::mqtt_silent_connection_callback,
                      message_callback=bbc_callback)
