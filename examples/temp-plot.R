library(mqtt) # devtools::install_github("hrbrmstr/mqtt")
library(jsonlite)
library(hrbrthemes)
library(tidyverse)

i <- 0 # initialize our counter
max_recs <- 50 # max number of readings to get

readings <- vector("character", max_recs)

# our callback function
temp_cb <- function(id, topic, payload, qos, retain) {

  i <<- i + 1 # update the counter
  readings[i] <<- readBin(payload, "character") # update our larger-scoped vector

  return(if (i==max_recs) "quit" else "go") # need to send at least "". "quit" == done

}

topic_subscribe(
  topic = "/outbox/crouton-demo/temperature",
  message_callback=temp_cb
)

# each reading looks like this:
# {"update": {"labels":[4631],"series":[[68]]}}
map(readings, fromJSON) %>%
  map(unlist) %>%
  map_df(as.list) %>%
  ggplot(aes(update.labels, update.series)) +
  geom_line() +
  geom_point() +
  labs(x="Reading", y="Temp (F)", title="Temperature via MQTT") +
  theme_ipsum_rc(grid="XY")
