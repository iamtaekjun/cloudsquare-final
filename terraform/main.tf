# ══════════════════════════════════════════════════════
# 호서대학교 2026학년도 LMS 클라우드 유지보수
# Root Module - 모든 모듈을 조합
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# 1. Network (VPC, Subnet, ACL, Route Table)
# ──────────────────────────────────────────────
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  subnet_lb_cidr     = var.subnet_lb_cidr
  subnet_app_cidr    = var.subnet_app_cidr
  subnet_dev_cidr    = var.subnet_dev_cidr
  subnet_db_cidr     = var.subnet_db_cidr
}

# ──────────────────────────────────────────────
# 2. Compute (서버 인스턴스)
# ──────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  subnet_lb_cidr     = var.subnet_lb_cidr
  subnet_app_cidr    = var.subnet_app_cidr
  subnet_dev_cidr    = var.subnet_dev_cidr
  subnet_db_cidr     = var.subnet_db_cidr
  subnet_app_id      = module.network.subnet_app_id
  subnet_dev_id      = module.network.subnet_dev_id
  subnet_db_id       = module.network.subnet_db_id
  login_key_name     = var.login_key_name
  server_image_name  = var.server_image_name
  webwas_server_type = var.webwas_server_type
  db_server_type     = var.db_server_type
  cache_server_type  = var.cache_server_type
  dev_server_type    = var.dev_server_type
  webwas_disk_size   = var.webwas_disk_size
  db_disk_size       = var.db_disk_size
  cache_disk_size    = var.cache_disk_size
  dev_disk_size      = var.dev_disk_size
  ssl_vpn_cidr       = var.ssl_vpn_cidr
}

# ──────────────────────────────────────────────
# 3. Load Balancer
# ──────────────────────────────────────────────
module "lb" {
  source = "./modules/lb"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_lb_id      = module.network.subnet_lb_id
  webwas_server_ids = module.compute.webwas_server_ids
}

# ──────────────────────────────────────────────
# 4. Storage (NAS, Object Storage, Backup)
# ──────────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  project_name      = var.project_name
  webwas_server_ids = module.compute.webwas_server_ids
  db_server_id      = module.compute.db_server_id
  nas_volume_size   = var.nas_volume_size
}

# ──────────────────────────────────────────────
# 5. Security (SSL VPN, Auto Scaling)
# ──────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  subnet_app_id         = module.network.subnet_app_id
  lms_domain            = var.lms_domain
  webwas_acg_id         = module.compute.webwas_acg_id
  server_image_id       = module.compute.server_image_number
  webwas_server_type    = var.webwas_server_type
  login_key_name        = var.login_key_name
  webwas_init_script_no = module.compute.webwas_init_script_no
  admin_allowed_ips     = var.admin_allowed_ips
}

# ──────────────────────────────────────────────
# 6. CDN (Global Edge, VOD Transcoder)
# ──────────────────────────────────────────────
module "cdn" {
  source = "./modules/cdn"

  project_name       = var.project_name
  media_bucket_name  = module.storage.media_bucket_name
  static_bucket_name = module.storage.static_bucket_name
  cdn_domain         = var.cdn_domain
  lms_domain         = var.lms_domain
}
