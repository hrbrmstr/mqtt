#ifndef MTEST_H
#define MTEST_H

#include <mosquittopp.h>

//' @export
class mqtt_r : public mosqpp::mosquittopp {

public:

  mqtt_r(std::string id, std::string host, int port=1883L);

  mqtt_r(std::string id, std::string host, int port,
         Rcpp::Function mess_cb,
         Rcpp::Function conn_cb, Rcpp::Function disconn_cb);

  ~mqtt_r();

  int connect(std::string host, int port=1883, int keepalive=60);
  int disconnect();
	int subscribe(int mid, std::string topic, int qos=0);
	int unsubscribe(int mid, std::string topic);
  int loop_start();
  int loop_stop(bool force=false);
	 int loop(int timeout=-1, int max_packets=1);
  void set_connection_cb(Rcpp::Function cbf);
  void set_discconn_cb(Rcpp::Function cbf);
  void set_publish_cb(Rcpp::Function cbf);
  void set_message_cb(Rcpp::Function cbf);
  void set_subscribe_cb(Rcpp::Function cbf);
  void set_unsubscribe_cb(Rcpp::Function cbf);
  void set_log_cb(Rcpp::Function cbf);
  void set_error_cb(Rcpp::Function cbf);

  void on_connect(int rc);
  void on_message(const struct mosquitto_message *message);
  void on_subscribe(int mid, int qos_count, const int *granted_qos);
	void on_disconnect(int rc);
	void on_publish(int mid);
	void on_unsubscribe(int mid);
	void on_log(int level, const char *str);
	void on_error();

private:

  Rcpp::Function ccb = Rcpp::Environment("package:mqtt")[".mqtt_connect_cb"];
  Rcpp::Function dcb = Rcpp::Environment("package:mqtt")[".mqtt_disconnect_cb"];
  Rcpp::Function pcb = Rcpp::Environment("package:mqtt")[".mqtt_publish_cb"];
  Rcpp::Function mcb = Rcpp::Environment("package:mqtt")[".mqtt_message_cb"];
  Rcpp::Function scb = Rcpp::Environment("package:mqtt")[".mqtt_subscribe_cb"];
  Rcpp::Function ucb = Rcpp::Environment("package:mqtt")[".mqtt_unsubscribe_cb"];
  Rcpp::Function lcb = Rcpp::Environment("package:mqtt")[".mqtt_log_cb"];
  Rcpp::Function ecb = Rcpp::Environment("package:mqtt")[".mqtt_error_cb"];

};

#endif