variable "project_name"       { type = string }
variable "vpc_id"             { type = string }
variable "vpc_cidr"           { type = string }
variable "subnet_lb_cidr"     { type = string }
variable "subnet_app_cidr"    { type = string }
variable "subnet_dev_cidr"    { type = string }
variable "subnet_db_cidr"     { type = string }
variable "subnet_app_id"      { type = string }
variable "subnet_dev_id"      { type = string }
variable "subnet_db_id"       { type = string }
variable "login_key_name"     { type = string }
variable "server_image_name"  { type = string }
variable "webwas_server_type" { type = string }
variable "db_server_type"     { type = string }
variable "cache_server_type"  { type = string }
variable "dev_server_type"    { type = string }
variable "webwas_disk_size"   { type = number }
variable "db_disk_size"       { type = number }
variable "cache_disk_size"    { type = number }
variable "dev_disk_size"      { type = number }

variable "ssh_port" {
  description = "SSH 접속 포트 (기본 22에서 변경 권장)"
  type        = string
  default     = "2222"  # 보안: 기본 포트 변경
}

variable "ssl_vpn_cidr" {
  description = "NCP SSL VPN IP 대역 (관리자 접근용)"
  type        = string
  default     = "172.16.0.0/23"
}
