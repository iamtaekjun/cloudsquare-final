variable "project_name"          { type = string }
variable "vpc_id"                { type = string }
variable "subnet_app_id"         { type = string }
variable "lms_domain"            { type = string }
variable "webwas_acg_id"         { type = string }
variable "server_image_id"       { type = string }
variable "webwas_server_type"    { type = string }
variable "login_key_name"        { type = string }

variable "admin_allowed_ips" {
  type    = list(string)
  default = []
}

variable "ssh_port" {
  type    = string
  default = "2222"
}
