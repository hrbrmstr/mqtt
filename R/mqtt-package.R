#' Interoperate with 'MQTT' Message Brokers
#'
#' MQTT' is a machine-to-machine ('M2M')/"Internet of Things" connectivity protocol. It
#' was designed as an extremely lightweight publish/subscribe messaging transport. It is
#' useful for connections with remote locations where a small code footprint is required
#' and/or network bandwidth is at a premium. For example, it has been used in sensors
#' communicating to a broker via satellite link, over occasional dial-up connections with
#' healthcare providers, and in a range of home automation and small device scenarios. It
#' is also ideal for mobile applications because of its small size, low power usage,
#' minimised data packets, and efficient distribution of information to one or many
#' receivers. Tools are provided to interoperate with 'MQTT' message brokers in R.
#'
#' @name mqtt
#' @docType package
#' @author Bob Rudis (bob@@rud.is)
#' @importFrom Rcpp sourceCpp
#' @importFrom uuid UUIDgenerate
#' @importFrom magrittr %>%
#' @importFrom rlang coerce_type f_rhs abort friendly_type caller_env
#' @importFrom methods new
#' @importFrom crayon green
#' @useDynLib mqtt
NULL

#' @title pipe
#' @description pipe
#' @name %>%
#' @export
NULL