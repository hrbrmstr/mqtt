context("basic functionality")
test_that("we can do something", {

  x <- 0

  my_msg_cb <- function(id, topic, payload, qos, retain) {
    x <<- x + 1
    return(if (x==5) "quit" else "continue")
  }

  topic_subscribe(message_callback=my_msg_cb)

  expect_equal(x, 6)

})
