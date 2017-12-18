library(mqtt)

# We're going to subscribe to *three* BBC subtitle feeds at the same time!
#
# We'll distinguish between them by coloring the topic and text differently.

# this is a named function object that displays BBC 2's subtitle feed when it get messages
moar_bbc <- function(id, topic, payload, qos, retain, con) {
  if (topic == "bbc/subtitles/bbc_two_england/raw") {
    cat(crayon::cyan(topic), crayon::blue(readBin(payload, "character")), "\n", sep=" ")
  }
}

mqtt_broker("makmeunique", "test.mosquitto.org", 1883L) %>% # connection info

  mqtt_silence(c("all")) %>% # silence all the development screen messages

  # subscribe to BBC 1's topic using a fully specified anonyous function

  mqtt_subscribe(
    "bbc/subtitles/bbc_one_london/raw",
    function(id, topic, payload, qos, retain, con) { # regular anonymous function
      if (topic == "bbc/subtitles/bbc_one_london/raw")
        cat(crayon::yellow(topic), crayon::green(readBin(payload, "character")), "\n", sep=" ")
    }) %>%

  # as you can see we can pipe-chain as many subscriptions as we like. the package
  # handles the details of calling each of them. This makes it possible to have
  # very focused handlers vs lots of "if/them/case_when" impossible-to-read functions.

  # Ahh. A tidy, elegant, succinct ~{} function instead

  mqtt_subscribe("bbc/subtitles/bbc_news24/raw", ~{ # tilde shortcut function (passing in named, pre-known params)
    if (topic == "bbc/subtitles/bbc_news24/raw")
      cat(crayon::yellow(topic), crayon::red(readBin(payload, "character")), "\n", sep=" ")
  }) %>%

  # And, a boring, but -- in the long run, better (IMO) -- named function object

  mqtt_subscribe("bbc/subtitles/bbc_two_england/raw", moar_bbc) %>% # named function

  mqtt_run() -> res # this runs until you Ctrl-C

