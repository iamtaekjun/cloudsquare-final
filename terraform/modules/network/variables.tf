variable "project_name"      { type = string }
variable "vpc_cidr"          { type = string }
variable "subnet_lb_cidr"    { type = string }
variable "subnet_natgw_cidr" { type = string }
variable "subnet_app_cidr"   { type = string }
variable "subnet_dev_cidr"   { type = string }
variable "subnet_db_cidr"    { type = string }
variable "zone" {
  type    = string
  default = "KR-2"
}
