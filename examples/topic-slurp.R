# log all seen topics to a file until interrupted

topic_slurp <- function(id, topic, payload, qos, retain) {
  cat(topic, "\n", sep="", file=sprintf("%s-topics.txt", Sys.Date()), append=TRUE)
  return("") # ctrl-c will terminate
}

mqtt::topic_subscribe(topic = "#", message_callback=topic_slurp)
