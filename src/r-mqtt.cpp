#include <Rcpp.h>

#include <csignal>
#include <cstdio>
#include <cstdint>
#include <cstring>

#include <unistd.h>

#include "mqtt-defs.h"

// we may be able to support more than one operation in the future so plan
// for it here.
// TODO disposal
// struct node {
//   RMQTTCallback rcb ;
//   node *next;
// };
//
// node rcb_list = *(new node);
// node *lstail = &rcb_list;

using namespace Rcpp;

static bool m_init = false; // TODO see if we really need this flag for intialization
static int run = 1; // if this goes to 0 (has a system interrupt) while an event loop is running, it will terminate

void handle_signal(int s) { run = 0; } // handle interrupt for ^^

// callback shell
//
// `obj` gets setup during the connection and points to a RMQTTCallback object
// which enables it to pluck out R things it needs so we can write
// callbacks in R vs C
void connect_callback(struct mosquitto *mosq, void *obj, int result) {

  RMQTTCallback *callback_ptr = (RMQTTCallback *)obj;
  RMQTTCallback callback_obj = *callback_ptr;

  callback_obj.call_conn_cb(result);

}

// callback shell
//
// `obj` gets setup during the connection and points to a RMQTTCallback object
// which enables it to pluck out R things it needs so we can write
// callbacks in R vs C
void disconnect_callback(struct mosquitto *mosq, void *obj, int rc) {

  RMQTTCallback *callback_ptr = (RMQTTCallback *)obj;
  RMQTTCallback callback_obj = *callback_ptr;

  callback_obj.call_disconn_cb(rc);

}

// callback shell
//
// `obj` gets setup during the connection and points to a RMQTTCallback object
// which enables it to pluck out R things it needs so we can write
// callbacks in R vs C
//
// special sauce here to watch for a return value from the object wrapper
// so it can issue a disconnect and stop looping. this can also happen
// if a special interrupt is triggered.
void message_callback(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message) {

  RMQTTCallback *callback_ptr = (RMQTTCallback *)obj;
  RMQTTCallback callback_obj = *callback_ptr;

  bool end_session = callback_obj.call_msg_cb(message);

  if (end_session | (!run)) mosquitto_disconnect(mosq);

}

// Get mosquitto library version
//
// Internal only function unlikely to get exposed to the user
//
// [[Rcpp::export]]
std::string mqtt_version() {
  int maj, min, rev;
  (void)mosquitto_lib_version(&maj, &min, &rev);
  return(std::to_string(maj) + "." + std::to_string(min) + "." + std::to_string(rev));
};

// Init the mosquitto library
//
// May expose this if an R DSL for the library is exposed
//
// [[Rcpp::export]]
bool mqtt_init() {
  m_init = (mosquitto_lib_init() == 0);
  return(m_init);
};

// Free resources when done
//
// May expose this if an R DSL for the library is exposed
//
// [[Rcpp::export]]
bool mqtt_free() { return(mosquitto_lib_cleanup() == 0); };


// The core function
//
// subscribe to a topic on an MQTT server
//
// TODO authentication support
// TODO encryption support
//
// [[Rcpp::export]]
void subscribe_(
    std::string host, int port, int keepalive,
    std::string client_id, std::string topic, int qos,
    Rcpp::Function connection_cb, Rcpp::Function message_cb,
    Rcpp::Function disconnect_cb
  ) {

  struct mosquitto *mosq;
  int rc = 0;

  signal(SIGINT, handle_signal);
  signal(SIGTERM, handle_signal);

  mosquitto_lib_init();

  RMQTTCallback rcb = RMQTTCallback();
  // node *cur_node = lstail;
  // lstail->rcb = rcb;

  // RMQTTCallback *ptr = &lstail->rcb;

  // lstail->next = new node;
  // lstail = lstail->next;

  // ptr->set_connect_callback(connection_cb);
  // ptr->set_message_callback(message_cb);
  // ptr->set_disconnect_callback(disconnect_cb);

  // mosq = mosquitto_new(client_id.c_str(), true, ptr);
  //
  // ptr->set_mosq(mosq);

  rcb.set_connect_callback(connection_cb);
  rcb.set_message_callback(message_cb);
  rcb.set_disconnect_callback(disconnect_cb);

  mosq = mosquitto_new(client_id.c_str(), true, &rcb);

  rcb.set_mosq(mosq);

  if (mosq) {

    mosquitto_connect_callback_set(mosq, connect_callback);
    mosquitto_message_callback_set(mosq, message_callback);

    rc = mosquitto_connect(mosq, host.c_str(), port, keepalive);

    mosquitto_subscribe(mosq, NULL, topic.c_str(), qos);

    mosquitto_loop_forever(mosq, -1, 1);

    mosquitto_destroy(mosq);

  }

  mosquitto_lib_cleanup();

}

