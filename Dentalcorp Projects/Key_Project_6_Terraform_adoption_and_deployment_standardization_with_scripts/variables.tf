variable "vpc-cidr" {
description = "VPC CIDR BLOCK"
type = string
}

variable "vpc-tag" {
description = "Name of the VPC"
type = string
}

variable "transit_gateway_attachment" {
description = "Name transit gateway attachment"
type = string
}

variable "transit-gateway-attachment" {
default = "tgw-"
description = "DO NOT CHANGE DEFAULT VALUE: ID of the transit gateway"
type = string
}

variable "tgw_subnet" {
  description = "List of subnets to associate with the VPC attachment"
  type        = list(string)
  default = ["x.x.x.x/xx","x.x.x.x/xx", "x.x.x.x/xx"]
}

variable "data_subnet" {
  description = "List of subnets to associate with the VPC attachment"
  type        = list(string)
  default = ["x.x.x.x/xx", "x.x.x.x/xx", "x.x.x.x/xx"]
}

variable "availability_zones" {
  default = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
}