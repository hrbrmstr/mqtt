library(mqtt)
library(purrr)
library(stringi)

# turn the pipe-separated, colon-delimeted lines into a proper list
.decode_payload <- function(.x) {
  .x <- readBin(.x, "character")
  .x <- stri_match_all_regex(.x, "([[:alpha:]]+):([[:digit:]\\.]+)")[[1]][,2:3]
  .x <- as.list(setNames(as.numeric(.x[,2]), .x[,1]))
  .x$timestamp <- as.POSIXct(.x$timestamp/1000, origin="1970-01-01 00:00:00")
  .x
}

# do it safely as the payload in MQTT can be anything
decode_payload <- purrr::safely(.decode_payload)

# change the client id
mqtt_broker("makemeuique", "broker.mqttdashboard.com", 1883L) %>%
  mqtt_silence(c("all")) %>%
  mqtt_subscribe("sfxrider/+/locations", ~{
    x <- decode_payload(payload)$result
    if (!is.null(x)) {
      cat(crayon::yellow(jsonlite::toJSON(x, auto_unbox=TRUE), "\n", sep=""))
    }
  }) %>%
  mqtt_run(times = 10000) -> out


