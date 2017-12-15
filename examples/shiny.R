# example showing hacky-use in a Shiny context
library(shiny)
library(mqtt)
library(hrbrthemes)
library(tidyverse)

ui <- fluidPage(
  plotOutput('plot')
)

server <- function(input, output) {

  get_temps <- function(n) {

    i <- 0
    max_recs <- n
    readings <- vector("character", max_recs)

    temp_cb <- function(id, topic, payload, qos, retain) {
      i <<- i + 1
      readings[i] <<- readBin(payload, "character")
      return(if (i==max_recs) "quit" else "go")
    }

    mqtt::topic_subscribe(topic = "/outbox/crouton-demo/temperature",
                    connection_callback = mqtt::mqtt_silent_connection_callback,
                    message_callback = temp_cb)

    purrr::map(readings, jsonlite::fromJSON) %>%
      purrr::map(unlist) %>%
      purrr::map_df(as.list)

  }

  values <- reactiveValues(x = NULL, y = NULL)

  observeEvent(invalidateLater(450), {
    new_response <- get_temps(1)
    if (length(new_response) != 0) {
      values$x <- c(values$x, new_response$update.labels)
      values$y <- c(values$y, new_response$update.series)
    }
  }, ignoreNULL = FALSE)

  output$plot <- renderPlot({
    xdf <- data.frame(xval = values$x, yval = values$y)
    ggplot(xdf, aes(x = xval, y=yval)) +
      geom_line() +
      geom_point() +
      theme_ipsum_rc(grid="XY")
  })

}

shinyApp(ui = ui, server = server)