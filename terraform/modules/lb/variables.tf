variable "project_name"       { type = string }
variable "vpc_id"             { type = string }
variable "subnet_lb_id"       { type = string }
variable "webwas_server_ids"  { type = list(string) }
variable "ssl_certificate_no" {
  type        = string
  description = "NCP SSL 인증서 번호 (콘솔에서 발급)"
  default     = ""
}
