output "vpc_id"        { value = ncloud_vpc.main.id }
output "subnet_lb_id"  { value = ncloud_subnet.lb.id }
output "subnet_app_id" { value = ncloud_subnet.app.id }
output "subnet_dev_id" { value = ncloud_subnet.dev.id }
output "subnet_db_id"  { value = ncloud_subnet.db.id }
