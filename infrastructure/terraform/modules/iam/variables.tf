variable "name" { type = string }
variable "media_bucket" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
