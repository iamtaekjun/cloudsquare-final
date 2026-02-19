# ssl_vpn_id, asg_id, launch_config_no: NCP Terraform 미지원 (콘솔 수동 설정)
output "admin_acg_id" { value = ncloud_access_control_group.admin_bastion.id }
