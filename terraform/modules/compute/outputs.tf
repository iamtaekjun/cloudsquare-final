output "webwas_server_ids"   { value = ncloud_server.webwas[*].id }
output "webwas_private_ips"  { value = ncloud_server.webwas[*].private_ip }
output "cache_server_id"     { value = ncloud_server.cache.id }
output "cache_private_ip"    { value = ncloud_server.cache.private_ip }
output "db_server_id"        { value = ncloud_server.db.id }
output "db_private_ip"       { value = ncloud_server.db.private_ip }
output "dev_server_id"       { value = ncloud_server.dev.id }
output "dev_private_ip"      { value = ncloud_server.dev.private_ip }
output "webwas_acg_id"             { value = ncloud_access_control_group.webwas.id }
output "server_image_number"       { value = data.ncloud_server_image_numbers.rocky.image_number_list[0].server_image_number }
output "webwas_init_script_no"     { value = ncloud_init_script.webwas.id }
output "login_key_private_key" {
  value     = ncloud_login_key.main.private_key
  sensitive = true
}
