# ══════════════════════════════════════════════════════
# Network Module - VPC / Subnet / Route Table / NAT GW
# 아키텍처: 10.0.0.0/16
#   ├── 10.0.0.0/24  : LB Subnet (Public)
#   ├── 10.0.1.0/24  : App Tier (Web/WAS, Cache)
#   ├── 10.0.2.0/24  : Dev Tier
#   └── 10.0.3.0/24  : DB Tier
# 보안: ACG(Access Control Group)로 처리 (Network ACL 불필요)
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# VPC
# ──────────────────────────────────────────────
resource "ncloud_vpc" "main" {
  name            = "${var.project_name}-vpc"
  ipv4_cidr_block = var.vpc_cidr
}

# ──────────────────────────────────────────────
# Subnets
# NOTE: NCP VPC에서 Internet Gateway는 Terraform 리소스가 없음.
# PUBLIC 서브넷은 자동으로 인터넷 연결됨.
# ──────────────────────────────────────────────

# LB Subnet (ALB dedicated Public Subnet)
resource "ncloud_subnet" "lb" {
  vpc_no         = ncloud_vpc.main.id
  name           = "${var.project_name}-subnet-lb"
  subnet         = var.subnet_lb_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
}

# NAT Gateway Subnet (PUBLIC/GEN - required for NAT GW)
resource "ncloud_subnet" "natgw" {
  vpc_no         = ncloud_vpc.main.id
  name           = "${var.project_name}-subnet-natgw"
  subnet         = var.subnet_natgw_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
}

# App Tier (Web/WAS + Cache) - Private
resource "ncloud_subnet" "app" {
  vpc_no         = ncloud_vpc.main.id
  name           = "${var.project_name}-subnet-app"
  subnet         = var.subnet_app_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
}

# Dev Tier - Private
resource "ncloud_subnet" "dev" {
  vpc_no         = ncloud_vpc.main.id
  name           = "${var.project_name}-subnet-dev"
  subnet         = var.subnet_dev_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
}

# DB Tier - Private
resource "ncloud_subnet" "db" {
  vpc_no         = ncloud_vpc.main.id
  name           = "${var.project_name}-subnet-db"
  subnet         = var.subnet_db_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
}

# ──────────────────────────────────────────────
# NAT Gateway & Route Table
# NOTE: ncloud_nat_gateway requires a specific subnet type that conflicts with
# Terraform provider behavior. Set up manually via NCP console:
#   VPC > NAT Gateway > Create
#   - Name: hoseo-lms-natgw
#   - VPC: hoseo-lms-vpc
#   - Subnet: hoseo-lms-subnet-natgw (10.0.4.0/24, PUBLIC/GEN)
#   - Zone: KR-2
# Then create a Route Table and add default route (0.0.0.0/0 -> NAT GW)
# Associate route table with app, dev, db subnets.
# ──────────────────────────────────────────────
