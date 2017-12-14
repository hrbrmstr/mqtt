# watch bbc 2 live subtitles meander by

bbc_callback <- function(id, topic, payload, qos, retain) {
  if (topic == "bbc/subtitles/bbc_two_england/raw") { # verify we got what we expected
    cat(crayon::green(readBin(payload, "character")), "\n", sep="")
  }
  return("") # ctrl-c will terminate
}

mqtt::topic_subscribe(topic = "bbc/subtitles/bbc_two_england/raw", message_callback=bbc_callback)
