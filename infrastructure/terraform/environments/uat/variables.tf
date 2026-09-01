variable "region" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "k8s_version" { type = string }
variable "node_instance_types" { type = list(string) }
variable "node_desired_size" { type = number }
variable "node_min_size" { type = number }
variable "node_max_size" { type = number }
variable "db_instance_class" { type = string }
variable "db_multi_az" { type = bool }
variable "db_password" {
  type      = string
  sensitive = true
}
