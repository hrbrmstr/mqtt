library(mqtt)
library(purrr)
library(stringi)

.decode_payload <- function(.x) {
  .x <- readBin(.x, "character")
  .x <- stri_match_all_regex(.x, "([[:alpha:]]+):([[:digit:]\\.]+)")[[1]][,2:3]
  .x <- as.list(setNames(as.numeric(.x[,2]), .x[,1]))
  .x$timestamp <- as.POSIXct(.x$timestamp/1000, origin="1970-01-01 00:00:00")
  .x
}

decode_payload <- purrr::safely(.decode_payload)

# change the id #pls
mqtt_broker("makemeuique", "broker.mqttdashboard.com", 1883L) %>%
  mqtt_silence(c("all")) %>%
  mqtt_subscribe("sfxrider/+/locations", ~{
    x <- decode_payload(payload)$result
    if (!is.null(x)) {
      cat(crayon::yellow(jsonlite::toJSON(x, auto_unbox=TRUE), "\n", sep=""))
    }
  }) %>%
  mqtt_begin() -> tracker # _begin!! not _run!!

# call this individually and have the callback update a
# larger scoped variable or Redis or a database. You
# can also just loop like this `for` setup.

for (i in 1:25) mqtt_loop(tracker, timeout = 1000)

mqtt_end(tracker) # this cleans up stuff!
