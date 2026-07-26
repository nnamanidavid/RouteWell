variable "prefix" {
  default = "routewell"
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.123.0.0/16"]
}

variable "subnet_web_address" {
  type    = list(string)
  default = ["10.123.1.0/27"]
}

variable "subnet_app_address" {
  type    = list(string)
  default = ["10.123.2.0/28"]
}

variable "subnet_db_address" {
  type    = list(string)
  default = ["10.123.3.0/28"]
}

variable "subnet_app_gateway_address" {
  type    = list(string)
  default = ["10.123.4.0/27"]
}