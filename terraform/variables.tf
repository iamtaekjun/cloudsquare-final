# ──────────────────────────────────────────────
# NCP 인증 정보
# ──────────────────────────────────────────────
variable "ncloud_access_key" {
  description = "NCP Access Key"
  type        = string
  sensitive   = true
}

variable "ncloud_secret_key" {
  description = "NCP Secret Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "NCP 리전"
  type        = string
  default     = "KR"
}

# ──────────────────────────────────────────────
# 프로젝트 공통
# ──────────────────────────────────────────────
variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
  default     = "hoseo-lms"
}

variable "environment" {
  description = "환경 구분 (prod / dev)"
  type        = string
  default     = "prod"
}

# ──────────────────────────────────────────────
# 네트워크
# ──────────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_app_cidr" {
  description = "App Tier (Web/WAS, Cache) 서브넷"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_dev_cidr" {
  description = "Dev Tier (CI/CD) 서브넷"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_db_cidr" {
  description = "DB Tier 서브넷"
  type        = string
  default     = "10.0.3.0/24"
}

variable "subnet_lb_cidr" {
  description = "Load Balancer 전용 서브넷"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_natgw_cidr" {
  description = "NAT Gateway 전용 서브넷 (PUBLIC/GEN)"
  type        = string
  default     = "10.0.4.0/24"
}

# ──────────────────────────────────────────────
# 서버 스펙
# ──────────────────────────────────────────────
variable "webwas_server_type" {
  description = "WEB/WAS 서버 스펙 코드 (Gen3 KVM, 8vCPU 16GB)"
  type        = string
  default     = "c8-g3a"
}

variable "db_server_type" {
  description = "DB 서버 스펙 코드 (Gen3 KVM, 8vCPU 32GB)"
  type        = string
  default     = "s8-g3a"  
}

variable "cache_server_type" {
  description = "Cache 서버 스펙 코드 (Gen3 KVM, 2vCPU 8GB)"
  type        = string
  default     = "s2-g3a"
}

variable "dev_server_type" {
  description = "Dev 서버 스펙 코드 (Gen3 KVM, 2vCPU 4GB)"
  type        = string
  default     = "c2-g3a" 
}

variable "server_image_name" {
  description = "서버 OS 이미지 이름 (Gen3 KVM)"
  type        = string
  default     = "rocky-8.10-base"
}

# ──────────────────────────────────────────────
# 스토리지 크기 (GB)
# ──────────────────────────────────────────────
variable "webwas_disk_size" {
  type    = number
  default = 50
}

variable "db_disk_size" {
  type    = number
  default = 500
}

variable "cache_disk_size" {
  type    = number
  default = 50
}

variable "dev_disk_size" {
  type    = number
  default = 200
}

variable "nas_volume_size" {
  description = "NAS 볼륨 크기 (GB, 최소 500)"
  type        = number
  default     = 500
}

# ──────────────────────────────────────────────
# SSH 키 이름
# ──────────────────────────────────────────────
variable "login_key_name" {
  description = "NCP 서버 접속용 SSH 키 이름"
  type        = string
  default     = "hoseo-lms-key"
}

# ──────────────────────────────────────────────
# CDN / 도메인
# ──────────────────────────────────────────────
variable "lms_domain" {
  description = "LMS 도메인"
  type        = string
  default     = "learn.hoseo.ac.kr"
}

variable "cdn_domain" {
  description = "CDN 도메인"
  type        = string
  default     = "cdn.hoseo.ac.kr"
}

# ──────────────────────────────────────────────
# 관리자 VPN 접근 허용 IP
# ──────────────────────────────────────────────
variable "admin_allowed_ips" {
  description = "관리자 접근 허용 IP 목록"
  type        = list(string)
  default     = []  # 실제 운영 시 관리자 IP 입력
}
