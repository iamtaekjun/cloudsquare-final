# ══════════════════════════════════════════════════════
# Security Module - IPS / SSL VPN / ACG 기반 보안
# SER-001 ~ SER-017 요구사항 반영
# ※ WAF는 별도 NCP 콘솔에서 수동 구성 (비용 문제)
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# SSL VPN (관리자 원격 접근)
# SER-011, SER-015, SER-017
# NOTE: ncloud_ssl_vpn은 Terraform에서 지원하지 않음.
# NCP 콘솔 > Security > SSL VPN에서 수동 생성:
#   - 이름: hoseo-lms-ssl-vpn
#   - VPC: hoseo-lms-vpc
#   - 사용자 계정 설정 후 관리자에게 배포
# ──────────────────────────────────────────────

# ──────────────────────────────────────────────
# 관리자 전용 ACG (VPN 접속 후 관리자만 SSH 허용)
# SER-008, SER-011 - 관리자 페이지 접근 통제
# ──────────────────────────────────────────────
resource "ncloud_access_control_group" "admin_bastion" {
  name        = "${var.project_name}-acg-admin"
  description = "관리자 접근 제어 그룹 (VPN 경유)"
  vpc_no      = var.vpc_id
}

resource "ncloud_access_control_group_rule" "admin_bastion" {
  count                   = length(var.admin_allowed_ips) > 0 ? 1 : 0
  access_control_group_no = ncloud_access_control_group.admin_bastion.id

  dynamic "inbound" {
    for_each = var.admin_allowed_ips
    content {
      protocol    = "TCP"
      ip_block    = inbound.value
      port_range  = var.ssh_port
      description = "Admin SSH access via VPN"
    }
  }
}

# ──────────────────────────────────────────────
# Auto Scaling (트래픽 급증 대응)
# FUR-002 - Auto-Scaling 방안, PER-006 동시사용자 3,500명
# NOTE: ncloud_launch_configuration은 Gen3 KVM 미지원 (XEN Gen2 전용).
# Gen3 KVM Auto Scaling은 NCP 콘솔에서 수동 구성:
#   NCP 콘솔 > Auto Scaling > Launch Configuration 생성
#   - 이미지: rocky-8.6-base (KVM)
#   - 스펙: s8-g3 (8vCPU/16GB)
#   - 최소: 2, 최대: 6, 기본: 2
#   - 스케일 아웃 조건: CPU > 70%
# ──────────────────────────────────────────────

# ──────────────────────────────────────────────
# Cloud Insight 알람 (CPU, Memory 모니터링)
# PER-008, PER-009
# NOTE: ncloud_cloud_insight_widget은 Terraform에서 지원하지 않음.
# NCP 콘솔 > Management > Cloud Insight에서 수동 설정:
#   - CPU > 90% 알람 (PER-008)
#   - Memory > 75% 알람 (PER-009)
#   - 알람 수신: 운영 담당자 이메일/SMS
# ──────────────────────────────────────────────

# ──────────────────────────────────────────────
# 보안 공지: 수동 구성 필요 항목
# ──────────────────────────────────────────────
# 아래 항목은 NCP 콘솔에서 수동 설정 필요:
# 1. IPS (Intrusion Prevention System) - NCP Security Monitoring 서비스
# 2. WAF - 필요 시 추가 도입 검토
# 3. DDoS Protection - NCP 기본 제공
# 4. 웹 취약점 점검 - 교육부 사이버안전센터 지원시스템 연계 (COR-004)
