#include <Rcpp.h>

#include <mosquitto.h>

class RMQTTCallback {

public:

  void set_connect_callback(Rcpp::Function f) { conn_cb_func = f; };
  void set_disconnect_callback(Rcpp::Function f) { disconn_cb_func = f; };
  void set_message_callback(Rcpp::Function f) { msg_cb_func = f; };

  void set_mosq(struct mosquitto *mosq) { our_mosq = mosq; };
  struct mosquitto *get_mosq() { return(our_mosq); };

  void call_disconn_cb(int rc) {
    disconn_cb_func(rc);
  };

  void call_conn_cb(int result) {
    conn_cb_func(result);
  };

  // special sauce here as well
  // if the R function `msg_cb_func` returns "quit"
  // that will be a trigger for the wrapper message callback function to
  // terminate the loop
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

  // these are just placeholders guaranteed to exist and
  // will also handle an arbitrary number of parameters

private:

  struct mosquitto *our_mosq = NULL;

  Rcpp::Function disconn_cb_func = Rcpp::Environment::base_env()["cat"];
  Rcpp::Function conn_cb_func = Rcpp::Environment::base_env()["cat"];
  Rcpp::Function msg_cb_func = Rcpp::Environment::base_env()["cat"];

};
