# 호서대학교 2026학년도 LMS 클라우드 유지보수

## 프로젝트 개요
- **클라이언트**: 호서대학교
- **기간**: 2026.3.1 ~ 2027.2.28 (12개월)
- **LMS**: Coursemos LMS (by ㈜유비온)
- **클라우드**: Naver Cloud Platform (NCP)
- **LMS URL**: https://learn.hoseo.ac.kr/

## 기술 스택
- IaC: Terraform (provider: NaverCloudPlatform/ncloud ~> 3.2)
- DBMS: MySQL
- WEB/WAS: Apache
- OS: Linux (CentOS/Rocky)
- CDN: NCP Global Edge
- 스토리지: NCP Object Storage + NAS

## 아키텍처 (VPC: 10.0.0.0/16)
```
Users → IPS/WAF → ALB → Web/WAS #1,#2 → Cache → DB
                              ↕
                         NAS/Object Storage
                              ↕
                      CDN (Global Edge) → VOD Transcoder
Admin → SSL VPN → (내부망 접근)
Dev Server (10.0.2.0/24) → CI/CD (Jenkins)
```

### 서브넷
| 서브넷 | CIDR | 용도 |
|--------|------|------|
| App Tier | 10.0.1.0/24 | Web/WAS #1, #2, Cache |
| Dev Tier | 10.0.2.0/24 | Dev Server (CI/CD) |
| DB Tier | 10.0.3.0/24 | DB Server (MySQL) |

## 서버 스펙
| 서버 | vCPU | RAM | Disk | 수량 |
|------|------|-----|------|------|
| WEB/WAS | 8 | 16GB | 50GB | 2 |
| DB | 8 | 32GB | 500GB | 1 |
| Cache | 2 | 8GB | 50GB | 1 |
| Dev | 2 | 4GB | 200GB | 1 |

## 프로젝트 구조
```
cloudsquare-final/
├── terraform/
│   ├── providers.tf          # NCP provider 설정
│   ├── variables.tf          # 변수 정의
│   ├── outputs.tf            # 출력값
│   ├── main.tf               # 루트 모듈
│   └── modules/
│       ├── network/          # VPC, Subnet, ACL, Route Table
│       ├── compute/          # 서버 인스턴스
│       ├── security/         # WAF, IPS, SSL VPN
│       ├── lb/               # Application Load Balancer
│       ├── storage/          # NAS, Object Storage
│       └── cdn/              # Global Edge CDN
├── scripts/
│   ├── install_webwas.sh     # Apache + Coursemos 설치
│   ├── install_db.sh         # MySQL 설치/설정
│   ├── install_cache.sh      # Redis 설치/설정
│   └── setup_dev.sh          # Dev 서버 Jenkins CI/CD 구성
└── README.md
```

## CI/CD 전략
- **Dev 서버** (10.0.2.0/24)에 Jenkins 설치
- 코드 변경 → Jenkins 빌드 → Web/WAS 서버 배포
- 배포: SSH 또는 NCP API를 통한 자동 배포
- 스테이징 테스트 후 프로덕션 배포

## 주요 SLA
- 장애 복구: 통보 후 2시간 내 착수, 12시간 내 복구
- 가용성: 24×365
- 동시 사용자: 3,500명 이상
- 응답시간: 3초 이내
- CPU: < 90%, Memory: < 75%

## NCP Gen3 KVM Terraform 제약사항
- `ncloud_block_storage`: KVM 미지원 → NCP 콘솔 수동 연결
- `ncloud_block_storage_snapshot`: KVM 미지원 → NCP 콘솔 스냅샷
- `access_control_group_configuration_no_list`: VPC 미지원 → NCP 콘솔 ACG 연결
- NAS `volume_name_postfix`: 영숫자만 허용 (하이픈·언더스코어 불가) → `replace()` 처리

## 보안 정책
- SSH 포트 기본값 변경 필수
- WAF 차단 정책 운영
- 관리자 페이지: 내부망 + IP/MAC 접근 제한
- SSL/HTTPS 전용
- 개인정보 DB 암호화 (KISA 인정 알고리즘)
- Admin 접근: SSL VPN 경유
