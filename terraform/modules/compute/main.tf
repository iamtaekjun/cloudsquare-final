# ══════════════════════════════════════════════════════
# Compute Module - 서버 인스턴스
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# SSH Login Key
# ──────────────────────────────────────────────
resource "ncloud_login_key" "main" {
  key_name = var.login_key_name
}

# 키 파일 로컬 저장 (보안 주의: .gitignore에 추가 필수)
resource "local_sensitive_file" "private_key" {
  content         = ncloud_login_key.main.private_key
  filename        = "${path.module}/../../../.ssh/${var.login_key_name}.pem"
  file_permission = "0600"
}

# ──────────────────────────────────────────────
# 서버 이미지 조회 (Gen3 KVM)
# server_image_name 예: "rocky-8.6-base", "rocky-8.10-base"
# ──────────────────────────────────────────────
data "ncloud_server_image_numbers" "rocky" {
  server_image_name = var.server_image_name

  filter {
    name   = "hypervisor_type"
    values = ["KVM"]
  }
}

# ──────────────────────────────────────────────
# Access Control Group (방화벽 보안 그룹)
# ──────────────────────────────────────────────

# WEB/WAS ACG
resource "ncloud_access_control_group" "webwas" {
  name        = "${var.project_name}-acg-webwas"
  description = "WEB/WAS 서버 보안 그룹"
  vpc_no      = var.vpc_id
}

resource "ncloud_access_control_group_rule" "webwas" {
  access_control_group_no = ncloud_access_control_group.webwas.id

  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_lb_cidr
    port_range  = "8080"
    description = "ALB에서 WAS 포트"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_dev_cidr
    port_range  = var.ssh_port
    description = "Dev 서버 배포용 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = var.ssh_port
    description = "SSL VPN 관리자 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_app_cidr
    port_range  = "6379"
    description = "Cache 서버 (Redis) 내부 통신"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = var.subnet_db_cidr
    port_range  = "3306"
    description = "DB 접속"
  }
  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "443"
    description = "HTTPS 아웃바운드"
  }
  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "80"
    description = "HTTP 아웃바운드"
  }
}

# Cache ACG
resource "ncloud_access_control_group" "cache" {
  name        = "${var.project_name}-acg-cache"
  description = "Cache (Redis) 서버 보안 그룹"
  vpc_no      = var.vpc_id
}

resource "ncloud_access_control_group_rule" "cache" {
  access_control_group_no = ncloud_access_control_group.cache.id

  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_app_cidr
    port_range  = "6379"
    description = "Web/WAS에서 Redis 접근"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_dev_cidr
    port_range  = var.ssh_port
    description = "Dev 서버 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = var.ssh_port
    description = "SSL VPN 관리자 SSH"
  }
}

# Dev ACG
resource "ncloud_access_control_group" "dev" {
  name        = "${var.project_name}-acg-dev"
  description = "Dev 서버 (CI/CD) 보안 그룹"
  vpc_no      = var.vpc_id
}

resource "ncloud_access_control_group_rule" "dev" {
  access_control_group_no = ncloud_access_control_group.dev.id

  inbound {
    protocol    = "TCP"
    ip_block    = var.vpc_cidr
    port_range  = var.ssh_port
    description = "VPC 내부 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = var.ssh_port
    description = "SSL VPN 관리자 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = "8080"
    description = "SSL VPN Jenkins Web UI"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.vpc_cidr
    port_range  = "8080"
    description = "Jenkins Web UI"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = var.subnet_app_cidr
    port_range  = var.ssh_port
    description = "App 서버 배포"
  }
  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "443"
  }
  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "80"
  }
}

# DB ACG
resource "ncloud_access_control_group" "db" {
  name        = "${var.project_name}-acg-db"
  description = "DB 서버 보안 그룹"
  vpc_no      = var.vpc_id
}

resource "ncloud_access_control_group_rule" "db" {
  access_control_group_no = ncloud_access_control_group.db.id

  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_app_cidr
    port_range  = "3306"
    description = "WEB/WAS MySQL 접근"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_dev_cidr
    port_range  = "3306"
    description = "Dev 서버 DB 관리"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.subnet_dev_cidr
    port_range  = var.ssh_port
    description = "Dev 서버 SSH"
  }
  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = var.ssh_port
    description = "SSL VPN 관리자 SSH"
  }
}

# NOTE: Gen3 KVM 서버 스펙 코드는 NCP 콘솔에서 확인 필요.
# 콘솔 > Server > 서버 생성 > 서버 타입에서 spec_code 확인
# 또는: ncloud vserver getServerSpecList --hypervisorType KVM

# ──────────────────────────────────────────────
# WEB/WAS 서버 (이중화: #1, #2)
# ──────────────────────────────────────────────
resource "ncloud_server" "webwas" {
  count = 2

  name                = "${var.project_name}-webwas-${count.index + 1}"
  server_image_number = data.ncloud_server_image_numbers.rocky.image_number_list[0].server_image_number
  server_spec_code    = var.webwas_server_type
  subnet_no           = var.subnet_app_id
  login_key_name      = ncloud_login_key.main.key_name

  # NOTE: access_control_group_configuration_no_list not supported in VPC
  # ACG must be attached manually via NCP console after server creation

  description = "호서대 LMS WEB/WAS 서버 ${count.index + 1}"
}

# NOTE: ncloud_block_storage is not supported for Gen3 KVM servers (XEN Gen2 only)
# "KVM not support getHypervisorCode by computeNo" error
# Additional storage must be attached manually via NCP console:
#   Server > Storage > Block Storage > Create
#   Attach to each webwas server as needed

# ──────────────────────────────────────────────
# Cache 서버 (Redis)
# ──────────────────────────────────────────────
resource "ncloud_server" "cache" {
  name                = "${var.project_name}-cache"
  server_image_number = data.ncloud_server_image_numbers.rocky.image_number_list[0].server_image_number
  server_spec_code    = var.cache_server_type
  subnet_no           = var.subnet_app_id
  login_key_name      = ncloud_login_key.main.key_name

  # NOTE: access_control_group_configuration_no_list not supported in VPC
  # ACG must be attached manually via NCP console after server creation

  description    = "Hoseo LMS Cache (Redis) server"
}

# NOTE: ncloud_block_storage not supported for KVM Gen3 - attach via NCP console

# ──────────────────────────────────────────────
# DB 서버 (MySQL)
# ──────────────────────────────────────────────
resource "ncloud_server" "db" {
  name                = "${var.project_name}-db"
  server_image_number = data.ncloud_server_image_numbers.rocky.image_number_list[0].server_image_number
  server_spec_code    = var.db_server_type
  subnet_no           = var.subnet_db_id
  login_key_name      = ncloud_login_key.main.key_name

  # NOTE: access_control_group_configuration_no_list not supported in VPC
  # ACG must be attached manually via NCP console after server creation

  description    = "Hoseo LMS DB server (MySQL)"
}

# NOTE: ncloud_block_storage not supported for KVM Gen3 - attach via NCP console (500GB SSD)

# ──────────────────────────────────────────────
# Dev 서버 (CI/CD - Jenkins)
# ──────────────────────────────────────────────
resource "ncloud_server" "dev" {
  name                = "${var.project_name}-dev"
  server_image_number = data.ncloud_server_image_numbers.rocky.image_number_list[0].server_image_number
  server_spec_code    = var.dev_server_type
  subnet_no           = var.subnet_dev_id
  login_key_name      = ncloud_login_key.main.key_name

  # NOTE: access_control_group_configuration_no_list not supported in VPC
  # ACG must be attached manually via NCP console after server creation

  description    = "Hoseo LMS Dev server"
}

# NOTE: ncloud_block_storage not supported for KVM Gen3 - attach via NCP console (200GB SSD)

