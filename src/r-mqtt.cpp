#include <Rcpp.h>

#include <signal.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include <mosquitto.h>

class RMQTTCallback {
public:
  void set_connect_callback(Rcpp::Function f) { conn_cb_func = f; };
  void set_message_callback(Rcpp::Function f) { msg_cb_func = f; };
  void call_conn_cb(int result) {
    conn_cb_func(result);
  };
  bool call_msg_cb(const struct mosquitto_message *message) {
    Rcpp::CharacterVector ret = msg_cb_func(
      message->mid,
      std::string(message->topic),
      Rcpp::RawVector((unsigned char *)message->payload, ((unsigned char *)message->payload)+message->payloadlen),
      message->qos,
      message->retain
    );
    return(ret[0] == "quit");
  };
private:
  Rcpp::Function conn_cb_func = Rcpp::Environment::base_env()["cat"];
  Rcpp::Function msg_cb_func = Rcpp::Environment::base_env()["cat"];
};

struct node {
  RMQTTCallback rcb ;
  node *next;
};

node rcb_list = *(new node);
node *lstail = &rcb_list;

using namespace Rcpp;

static bool m_init = false;
// static int run = 1;

// void handle_signal(int s) { run = 0; }

void connect_callback(struct mosquitto *mosq, void *obj, int result) {

  RMQTTCallback *callback_ptr = (RMQTTCallback *)obj;
  RMQTTCallback callback_obj = *callback_ptr;
  callback_obj.call_conn_cb(result);

}

void message_callback(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message) {

  RMQTTCallback *callback_ptr = (RMQTTCallback *)obj;
  RMQTTCallback callback_obj = *callback_ptr;

 bool ret = callback_obj.call_msg_cb(message);

 if (ret) mosquitto_disconnect(mosq);

}

//' Get mosquitto library version
//'
// [[Rcpp::export]]
std::string mqtt_version() {
  int maj, min, rev, ret = mosquitto_lib_version(&maj, &min, &rev);
  return(std::to_string(maj) + "." + std::to_string(min) + "." + std::to_string(rev));
};

//' Get mosquitto library version
//'
// [[Rcpp::export]]
bool mqtt_init() {
  m_init = (mosquitto_lib_init() == 0);
  return(m_init);
};

//' Free resources when done
//'
// [[Rcpp::export]]
bool mqtt_free() { return(mosquitto_lib_cleanup() == 0); };

// [[Rcpp::export]]
void subscribe(
    std::string host, int port, int keepalive,
    std::string client_id, std::string topic, int qos,
    Rcpp::Function connection_cb, Rcpp::Function message_cb
  ) {

  // char clientid[24];
  struct mosquitto *mosq;
  int rc = 0;
  //
  // signal(SIGINT, handle_signal);
  // signal(SIGTERM, handle_signal);

  if (!m_init) mosquitto_lib_init();

  RMQTTCallback rcb = RMQTTCallback();
  lstail->rcb = rcb;

  RMQTTCallback *ptr = &lstail->rcb;

  lstail-> next = new node;
  lstail = lstail->next;

  ptr->set_connect_callback(connection_cb);
  ptr->set_message_callback(message_cb);

  mosq = mosquitto_new(client_id.c_str(), true, ptr);

  if (mosq) {

    mosquitto_connect_callback_set(mosq, connect_callback);
    mosquitto_message_callback_set(mosq, message_callback);

    rc = mosquitto_connect(mosq, host.c_str(), port, keepalive);

    mosquitto_subscribe(mosq, NULL, topic.c_str(), qos);

    mosquitto_loop_forever(mosq, -1, 1);

    // while(run) {
    //   rc = mosquitto_loop(mosq, -1, 1);
    //   if(run && rc) {
    //     printf("connection error!\n");
    //     sleep(10);
    //     mosquitto_reconnect(mosq);
    //   }
    // }

    mosquitto_destroy(mosq);

  }

  mosquitto_lib_cleanup();

}

