# ══════════════════════════════════════════════════════
# Storage Module - NAS / Object Storage / Backup
# FUR-001 (NAS, Snapshot Backup, Object Storage)
# SER-010 (정책 설정 정보 암호화 백업)
# ══════════════════════════════════════════════════════

# ──────────────────────────────────────────────
# NAS (Network Attached Storage)
# 서버 간 공유 파일시스템 (LMS 업로드 파일, 콘텐츠)
# ──────────────────────────────────────────────
resource "ncloud_nas_volume" "main" {
  volume_name_postfix     = replace(replace(var.project_name, "-", ""), "_", "")
  volume_size             = var.nas_volume_size  # GB (최소 500GB)
  volume_allotment_protocol_type = "NFS"

  # NFS 마운트 허용 서버 목록 (App Tier)
  server_instance_no_list = var.webwas_server_ids

  description = "호서대 LMS 공유 스토리지 (콘텐츠, 업로드 파일)"
}

# ──────────────────────────────────────────────
# Object Storage
# CDN 원본 저장소 + 정적 파일 + 백업
# FUR-001, FUR-004
# ──────────────────────────────────────────────

# LMS 미디어 버킷 (VOD 원본)
resource "ncloud_objectstorage_bucket" "media" {
  bucket_name = "${var.project_name}-media"
}

# 정적 리소스 버킷 (CSS, JS, 이미지)
resource "ncloud_objectstorage_bucket" "static" {
  bucket_name = "${var.project_name}-static"
}

# 백업 버킷 (DB 백업, 소스코드 백업)
resource "ncloud_objectstorage_bucket" "backup" {
  bucket_name = "${var.project_name}-backup"
}

# ──────────────────────────────────────────────
# Block Storage Snapshot - NCP 콘솔 수동 설정
# FUR-001 (Snapshot Backup), SER-010
# NOTE: ncloud_block_storage_snapshot requires block_storage_instance_no from
# ncloud_block_storage, which is not supported for KVM Gen3 servers.
# Configure snapshots manually via NCP console:
#   Server > Storage > Block Storage > select volume > Create Snapshot
# ──────────────────────────────────────────────

# NOTE: 아래 기능은 NCP Terraform 프로바이더에서 미지원 → NCP 콘솔 수동 설정
#
# [Object Storage 버전 관리 - SER-010]
#   NCP 콘솔 > Object Storage > hoseo-lms-backup 버킷 > 버전 관리 > 사용
#
# [수명주기 정책]
#   NCP 콘솔 > Object Storage > hoseo-lms-backup 버킷
#   > 수명주기 관리 > 규칙 추가
#   - 90일 후 Archive 이동, 365일 후 삭제
