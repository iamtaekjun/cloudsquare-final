# ══════════════════════════════════════════════════════
# Load Balancer Module - Application Load Balancer
# FUR-001 (로드밸런서), FUR-002 (이중화, 고가용성)
# PER-006 (동시 사용자 3,500명)
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# Application Load Balancer
# ──────────────────────────────────────────────
resource "ncloud_lb" "main" {
  name           = "${var.project_name}-alb"
  network_type   = "PUBLIC"
  type           = "APPLICATION"
  subnet_no_list = [var.subnet_lb_id]

  description = "호서대 LMS Application Load Balancer"
}

# ──────────────────────────────────────────────
# Target Group (WEB/WAS 서버들)
# ──────────────────────────────────────────────
resource "ncloud_lb_target_group" "webwas" {
  name        = "${var.project_name}-tg-webwas"
  vpc_no      = var.vpc_id
  target_type = "VSVR"
  protocol    = "HTTP"
  port        = 8080
  description = "WEB/WAS target group"

  health_check {
    protocol        = "HTTP"
    http_method     = "GET"
    port            = 8080
    url_path        = "/health"   # Coursemos 헬스체크 경로
    cycle           = 30          # 30초 간격
    up_threshold    = 2           # 2회 성공 시 UP
    down_threshold  = 3           # 3회 실패 시 DOWN
  }

  use_sticky_session = true  # 세션 고정 (LMS 로그인 상태 유지)
  algorithm_type     = "RR"  # Round Robin
}

# Target Group에 WEB/WAS 서버 추가
resource "ncloud_lb_target_group_attachment" "webwas" {
  target_group_no = ncloud_lb_target_group.webwas.target_group_no
  target_no_list  = var.webwas_server_ids
}

# ──────────────────────────────────────────────
# Listener - HTTP (80)
# NOTE: HTTPS listener requires SSL certificate provisioned in NCP console first.
# After SSL cert is ready, add ncloud_lb_listener "https" with ssl_certificate_no.
# ──────────────────────────────────────────────
resource "ncloud_lb_listener" "http" {
  load_balancer_no = ncloud_lb.main.load_balancer_no
  protocol         = "HTTP"
  port             = 80
  target_group_no  = ncloud_lb_target_group.webwas.target_group_no
}
