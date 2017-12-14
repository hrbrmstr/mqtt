showall_callback <- function(id, topic, payload, qos, retain) {
  try( # may get local encoding issues
    cat(
    crayon::yellow(topic), " : ",
    crayon::green(stringi::stri_enc_toutf8(readBin(payload, "character"))), "\n",
    sep=""
  ), silent=TRUE
  )
  return("") # ctrl-c will terminate
}

mqtt::topic_subscribe(topic = "#", message_callback=showall_callback)
