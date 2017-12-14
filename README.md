
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

    ##  Do you think you might have taken on
    ##  just a little bit too much today,
    ##  Tom?
    ##  Yeah, I probably did.
    ##  Yeah, that didn't go very well.
    ##  Yeah, I honestly
    ##  just tried too much,
    ##  and should have concentrated
    ##  on that dessert more.
    ##  The dessert was just rubbish.
    ##  Finally, Louisa has cooked duck
    ##  breast served with crispy ginger,
    ##  with caramelised endive, turnips,
    ##  green beans, and bread sauce,
    ##  finished with a ginger
    ##  and orange sauce.
    ##  The sauce is divine.
    ##  There is a warmth in there of the
    ##  ginger coming through with the acid
    ##  of the orange cutting the richness.
    ##  Stunning dish,
    ##  but I just have one problem
    ##  with this.
    ##  One thing that I was so looking
    ##  forward to that I'm not tasting,
    ##  and that's the bread sauce.
    ##  I've seen you before mingle East
    ##  and West really, really well,
    ##  and for me you've done it
    ##  here brilliantly.
    ##  That sauce, ginger and orange
    ##  together, is brilliant.
    ##  I have to say, the duck
    ##  is slightly over for my liking.
    ##  It's a bit on the chewy side.
    ##  But, for me, that ginger that's been
    ##  deep-fried has got this slight heat
    ##  left on the palate, and it's divine.
    ##  I guess what you did say was you
    ##  wanted to bring the intensity of the
    ##  flavours to your cooking.
    ##  Well, you definitely did that.
    ##  Thank you.
    ##  Louise's dessert is poached
    ##  apricots, almond frangipane,
    ##  apricot puree,
    ##  goat's curd,
    ##  almond caramel, crumble,
    ##  and an almond granita.
    ##  The granita is nice,
