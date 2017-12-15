# watch bbc one live subtitles meander by

bbc_callback <- function(id, topic, payload, qos, retain) {
  cat(crayon::green(readBin(payload, "character")), "\n", sep="")
  return("") # ctrl-c will terminate
}

mqtt::topic_subscribe(topic = "bbc/subtitles/bbc_one_london/raw", message_callback=bbc_callback)

