variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_cidrs" { type = list(string) }
variable "engine_version" {
  type    = string
  default = "15.5"
}
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "db_name" {
  type    = string
  default = "strapi"
}
variable "username" {
  type    = string
  default = "strapi"
}
variable "password" {
  type      = string
  sensitive = true
}
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
