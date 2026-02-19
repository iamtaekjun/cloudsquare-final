variable "project_name"             { type = string }
variable "webwas_server_ids"        { type = list(string) }
variable "db_server_id"             { type = string }
variable "nas_volume_size" {
  type    = number
  default = 500
}
