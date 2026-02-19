# ══════════════════════════════════════════════════════
# 전체 인프라 출력값
# ══════════════════════════════════════════════════════

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_domain" {
  description = "Application Load Balancer 도메인"
  value       = module.lb.alb_domain
}

output "webwas_private_ips" {
  description = "WEB/WAS 서버 사설 IP 목록"
  value       = module.compute.webwas_private_ips
}

output "cache_private_ip" {
  description = "Cache 서버 사설 IP"
  value       = module.compute.cache_private_ip
}

output "db_private_ip" {
  description = "DB 서버 사설 IP"
  value       = module.compute.db_private_ip
  sensitive   = true
}

output "dev_private_ip" {
  description = "Dev 서버 사설 IP (Jenkins)"
  value       = module.compute.dev_private_ip
}

# NAT Gateway IP는 NCP 콘솔 수동 설정 후 확인
# output "nat_gateway_ip" - NCP 콘솔 > VPC > NAT Gateway에서 확인

output "nas_mount_path" {
  description = "NAS 마운트 경로"
  value       = module.storage.nas_mount_path
}

# CDN 도메인은 NCP 콘솔 수동 설정 후 확인 (Terraform 미지원)
# output "cdn_domain"        - NCP 콘솔 > CDN > Global Edge에서 확인
# output "static_cdn_domain" - NCP 콘솔 > CDN > Global Edge에서 확인

output "media_bucket" {
  description = "미디어 Object Storage 버킷명"
  value       = module.storage.media_bucket_name
}

output "ssh_private_key" {
  description = "SSH 접속 키 (관리자용)"
  value       = module.compute.login_key_private_key
  sensitive   = true
}
