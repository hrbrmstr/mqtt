
# mqtt

Interoperate with ‘MQTT’ Message Brokers

## Description

‘MQTT’ is a machine-to-machine (‘M2M’)/“Internet of Things” connectivity
protocol. It was designed as an extremely lightweight publish/subscribe
messaging transport. It is useful for connections with remote locations
where a small code footprint is required and/or network bandwidth is at
a premium. For example, it has been used in sensors communicating to a
broker via satellite link, over occasional dial-up connections with
healthcare providers, and in a range of home automation and small device
scenarios. It is also ideal for mobile applications because of its small
size, low power usage, minimised data packets, and efficient
distribution of information to one or many receivers. Tools are provided
to interoperate with ‘MQTT’ message brokers in R.

## What You Need To Get This Working

You need to install the [`mosquitto`
libraries](https://mosquitto.org/download/) and ensure they’re on your
system `PATH` so R can find them. This will be easier in the future, but
coarse for the moment.

For macOS, that’s as easy as:

    brew install mosquitto

For Debian/Ubuntu, it will be something like:

    sudo apt install libmosquitto-dev

For Windows folks: install Linux or get a mac ;-) Seriously, I’m hoping
to have support for that soon.

## Current Functionality

You can subscribe to a topic on a server over plaintext. No
authentication methods are supported (yet) and no ability to use
encryption exists (yet).

When you subscribe, you should pass in a “callback handler”. Said
handler should have the same “signature” as the built-in default one,
which
    is:

    mqtt_default_message_callback <- function(id, topic, payload, qos, retain)

Those parameters are:

  - `id`: the message id
  - `topic`: the message topic
  - `payload`: the message payload (raw)
  - `qos`: the effective qos for the message
  - `retain`: is this message marked as “retain”?

`payload` is a raw vector. The example below shows how to work with this
data.

If you return “`quit`” from this function, the subscription will be
closed and control return to R.

I can see that publishing data to an MQTT broker would be useful for R
so that is on the TODO.

PLEASE file an issue and/or PR if you have ideas in mind for this. I
have more “evil” notions in mind (quantifiying expousure of sensitive
data on public MQTT channels). I suspect others have “real” needs for
this.

## What’s Inside The Tin

The following functions are implemented:

  - `topic_subscribe`: Subscribe to an MQTT Topic

## Installation

``` r
devtools::install_github("hrbrmstr/mqtt")
```

## Usage

``` r
library(mqtt)

# current verison
packageVersion("mqtt")
```

    ## [1] '0.1.0'

``` r
# internal function to see which mosquitto library is being used
print(mqtt:::mqtt_version())
```

    ## [1] "1.4.14"

### Live subtitles

For whatever reason, someone is using the public `test.mosquitto.org`
plaintext broker to push out live subtitles. It’s strangely mezmerizing
to watch it slowly scroll by. Let’s see the next 50 (as of the time this
Rmd
ran):

``` r
# We are going to cap it at 50 so we have to initialize a global we'll update
x <- 0

# Now, we need a callback function. This will get called everytime we get a message.
# the `topic` string will be passed in so you can compare that quickly.
# the `payload` is a raw vector since this can be pretty strange data (esp if you 
# subscribe to a wildcard).
# 
# You can use `rawToChar()` if you know it's going to be safe, but `readBin()` is
# a tad safter. Ideally, the package will have some sanitizing functions to make
# this easier and more robust.
my_msg_cb <- function(id, topic, payload, qos, retain) {
  
  if (topic == "bbc/subtitles/bbc_two_england/raw") { # when we see BBC 2 msgs, we'll cat them
    x <<- x + 1
    cat(readBin(payload, "character"), "\n", sep="")
  }

  return(if (x==50) "quit" else "continue") # "continue" can be "". anything but "quit"
}

# now, we'll subscribe to a wildcard topic at `test.mosquitto.org` on port 1883. 
# those are defaults in `topic_subscribe()` to make it easier to have some quick
# wun with the package.
topic_subscribe(message_callback=my_msg_cb)
```

    ## Default connect callback result: 0

    ##  They really were killers.
    ##  By this stage of the Blitz,
    ##  a clear pattern to the terrifying
    ##  night raids had emerged.
    ##  First, elite pathfinders dropped
    ##  flares and incendiaries
    ##  to illuminate the target area.
    ##  Then wave after wave of bombers
    ##  dropped hundreds of high explosives
    ##  to destroy water mains and cripple
    ##  the firefighting effort. . .
    ##  . .and tens of thousands more
    ##  incendiaries to sow countless fires
    ##  that grew into an inferno.
    ##  By the time Martin Reiser and the
    ##  rest of his Heinkel bomber unit
    ##  took off, heading over the
    ##  English Channel for Bristol,
    ##  the pathfinders,
    ##  known as the Firelighters,
    ##  were already over the city and had
    ##  begun the night's work.
    ##  Like many other Bristolians that
    ##  Sunday evening,
    ##  Geoffrey Serle and his father had
    ##  been attending church
    ##  when the raid began.
    ##  It was a nice, quiet Sunday evening,
    ##  as usual, in the church.
    ##  And to suddenly see the sky light up
    ##  like that, all of a sudden,
    ##  with flares and
    ##  being November, I said, "Dad, look.
    ##  There are fireworks still around. "
    ##  Of course, he knew that was not the
    ##  case, and they were flares from the
    ##  Pathfinder bombers who were lighting
    ##  up the city
    ##  before the main bomber force
    ##  arrived.
    ##  And they were heading towards
    ##  St Peter's Church
    ##  at the top of Castle Street.
    ##  If your memory stretches back to the
    ##  '30s, you'll remember this.
    ##  Cock And Bottle Lane really did
    ##  exist - one of any number of narrow
    ##  alleyways that led
    ##  into Castle Street,
    ##  which ran from Old Market to
