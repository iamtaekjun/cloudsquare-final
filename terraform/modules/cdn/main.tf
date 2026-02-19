# ══════════════════════════════════════════════════════
# CDN Module - Global Edge (VOD CDN)
# FUR-004 - CDN 서비스 제공
# - MP4 VOD 스트리밍 (무제한)
# - HTTPS 전송 (SSL 인증서)
# - 진도처리, 자동 출석 체크 연계
# - 등록 도메인 접근 제한
# ══════════════════════════════════════════════════════

# NOTE: NCP Terraform 프로바이더는 CDN/VOD 리소스를 지원하지 않음.
# 아래 항목은 NCP 콘솔에서 수동 구성 필요:
#
# [1. VOD Transcoder - FUR-004]
#   NCP 콘솔 > Media > VOD Station
#   - 스토리지 버킷: hoseo-lms-media (Object Storage)
#   - 트랜스코딩 프로파일: 720p, 1080p
#
# [2. Global Edge CDN - FUR-004]
#   NCP 콘솔 > CDN > Global Edge
#   ① VOD CDN:
#      - 원본: hoseo-lms-media.kr.object.ncloudstorage.com
#      - 도메인: cdn-media.hoseo.ac.kr
#      - 접근 제한: 등록 도메인(hoseo.ac.kr)만 허용
#   ② 정적 리소스 CDN:
#      - 원본: hoseo-lms-static.kr.object.ncloudstorage.com
#      - 도메인: cdn-static.hoseo.ac.kr
#
# [3. SSL 인증서 - FUR-004]
#   NCP 콘솔 > CDN > 인증서 관리 > *.hoseo.ac.kr 와일드카드 등록
#
# Object Storage 버킷은 storage 모듈에서 Terraform으로 생성됨.
