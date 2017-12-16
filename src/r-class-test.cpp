#include <Rcpp.h>

#include <csignal>
#include <cstdio>
#include <cstdint>
#include <cstring>

#include <unistd.h>

#include "r-class-test.h"

#include <mosquittopp.h>

using namespace Rcpp;

// mqtt_r::mqtt_r(const char *id, const char *host, int port) : mosquittopp(id) {
//
//   int keepalive = 60;
//   connect(host, port, keepalive);
//
// };

// mqtt_r::mqtt_r() {
//
//   int keepalive = 60;
//   connect("test.mosquitto.org", 1883L, keepalive);
//
// };

mqtt_r::mqtt_r(std::string id, std::string host, int port) : mosquittopp(id.c_str(), true) {

  Rcout << "init" << std::endl;

  mosqpp::lib_init();

  int keepalive = 60;
  Rcout << "conn " << connect(host.c_str(), port, keepalive) << std::endl;

} ;

mqtt_r::mqtt_r(std::string id, std::string host, int port,
               Rcpp::Function mess_cb,
               Rcpp::Function conn_cb,
               Rcpp::Function disconn_cb) : mosquittopp(id.c_str()) {


  mosqpp::lib_init();

  int keepalive = 60;
  connect(host.c_str(), port, keepalive);

  ccb = conn_cb;
  mcb = mess_cb;
  dcb = disconn_cb;

  loop_start();

};

mqtt_r::~mqtt_r() {
  loop_stop();
  mosqpp::lib_cleanup();
};

int mqtt_r::connect(std::string host, int port, int keepalive) {
  return(mosquittopp::connect(host.c_str(), port, keepalive));
};

int mqtt_r::disconnect() {
  return(mosquittopp::disconnect());
}

int mqtt_r::loop_start() {
  return(mosquittopp::loop_start());
};

int mqtt_r::loop_stop(bool force) {
  return(mosquittopp::loop_stop(force));
}

int mqtt_r::loop(int timeout, int max_packets) {
  return(mosquittopp::loop(timeout, max_packets));
};

int mqtt_r::subscribe(int mid, std::string topic, int qos) {
  return(mosquittopp::subscribe(&mid, topic.c_str(), qos));
};

int mqtt_r::unsubscribe(int mid, std::string topic){
  return(mosquittopp::unsubscribe(&mid, topic.c_str()));
};

void mqtt_r::on_connect(int rc) { ccb(rc); };

void mqtt_r::on_message(const struct mosquitto_message *message) {
  mcb(
    message->mid,
    std::string(message->topic),
    Rcpp::RawVector((unsigned char *)message->payload, ((unsigned char *)message->payload)+message->payloadlen),
    message->qos,
    message->retain
  );
};

void mqtt_r::on_subscribe(int mid, int qos_count, const int *granted_qos) {
  scb(mid, qos_count);
};

void mqtt_r::on_disconnect(int rc) { dcb(rc); };
void mqtt_r::on_publish(int mid) { pcb(mid); };
void mqtt_r::on_unsubscribe(int mid) { scb(mid); };
void mqtt_r::on_log(int level, const char *str) { lcb(level, std::string(str)); };
void mqtt_r::on_error() { ecb(); };

void mqtt_r::set_connection_cb(Rcpp::Function cbf) { ccb = cbf; };
void mqtt_r::set_discconn_cb(Rcpp::Function cbf) { dcb = cbf; };
void mqtt_r::set_publish_cb(Rcpp::Function cbf) { pcb = cbf; };
void mqtt_r::set_message_cb(Rcpp::Function cbf) { mcb = cbf; };
void mqtt_r::set_subscribe_cb(Rcpp::Function cbf) { scb = cbf; };
void mqtt_r::set_unsubscribe_cb(Rcpp::Function cbf) { ucb = cbf; };
void mqtt_r::set_log_cb(Rcpp::Function cbf) { lcb = cbf; };
void mqtt_r::set_error_cb(Rcpp::Function cbf) { ecb = cbf; };


RCPP_MODULE(MQTT) {

  using namespace Rcpp;

  class_<mqtt_r>("mqtt_r")
    // .default_constructor("Default constructor")
       .constructor<std::string, std::string, int>("constructor")
       .constructor<std::string, std::string, int, Rcpp::Function, Rcpp::Function, Rcpp::Function>("Con/Mess/Dis")
       .method("connect", &mqtt_r::connect)
       .method("disconnect", &mqtt_r::disconnect)
       .method("loop_start", &mqtt_r::loop_start)
       .method("loop_stop", &mqtt_r::loop_stop)
       .method("loop", &mqtt_r::loop)
       .method("subscribe", &mqtt_r::subscribe)
       .method("unsubscribe", &mqtt_r::unsubscribe)
       .method("set_connection_cb", &mqtt_r::set_connection_cb)
       .method("set_discconn_cb", &mqtt_r::set_discconn_cb)
       .method("set_publish_cb", &mqtt_r::set_publish_cb)
       .method("set_message_cb", &mqtt_r::set_message_cb)
       .method("set_subscribe_cb", &mqtt_r::set_subscribe_cb)
       .method("set_unsubscribe_cb", &mqtt_r::set_unsubscribe_cb)
       .method("set_log_cb", &mqtt_r::set_log_cb)
       .method("set_error_cb", &mqtt_r::set_error_cb)
    ;

}
