# 호서대학교 2026학년도 LMS 클라우드 유지보수 인프라

나라장터 제안 요구사항(RFP)을 기반으로, Naver Cloud Platform(NCP) 위에 Coursemos LMS 클라우드 인프라를 **Terraform IaC**로 구성한 프로젝트입니다.

| 항목 | 내용 |
|------|------|
| 대상 | 호서대학교 LMS (https://learn.hoseo.ac.kr) |
| 클라우드 | Naver Cloud Platform (NCP) |
| IaC | Terraform `NaverCloudPlatform/ncloud ~> 3.2` |
| OS | Rocky Linux 8 (Gen3 KVM) |
| 기간 | 2026.3.1 ~ 2027.2.28 |

---

## 아키텍처

```
                    ┌─────────────────────────────────────────────────────┐
                    │                  VPC (10.0.0.0/16)                  │
                    │                                                      │
Internet ──► IPS/WAF ──► ALB (10.0.0.0/24)                              │
                    │      │                                               │
                    │      ├──► WEB/WAS #1 ─┐   App Tier (10.0.1.0/24)  │
                    │      └──► WEB/WAS #2 ─┤                             │
                    │                        ├──► Cache (Redis)            │
                    │                        │                             │
                    │                        └──► DB (MySQL) (10.0.3.0/24)│
                    │                                                      │
                    │  Dev (Jenkins) (10.0.2.0/24)                        │
                    │                                                      │
                    │  NAS ↔ WEB/WAS (NFS 마운트)                         │
                    │  Object Storage ↔ CDN (Global Edge)                 │
                    └─────────────────────────────────────────────────────┘

Admin ──► SSL VPN ──► 내부망 접근
```

### 서브넷 구성

| 서브넷 | CIDR | 용도 |
|--------|------|------|
| LB | 10.0.0.0/24 | Application Load Balancer |
| App Tier | 10.0.1.0/24 | Web/WAS #1·#2, Cache(Redis) |
| Dev Tier | 10.0.2.0/24 | Dev Server (Jenkins CI/CD) |
| DB Tier | 10.0.3.0/24 | DB Server (MySQL) |
| NAT GW | 10.0.4.0/24 | NAT Gateway (Public) |

---

## 서버 스펙

| 서버 | vCPU | RAM | 디스크 | 수량 |
|------|------|-----|--------|------|
| WEB/WAS | 8 | 16GB | 50GB | 2 |
| DB | 8 | 32GB | 50GB + 500GB SSD | 1 |
| Cache | 2 | 8GB | 50GB | 1 |
| Dev | 2 | 4GB | 50GB + 200GB SSD | 1 |

---

## 프로젝트 구조

```
cloudsquare-final/
├── terraform/
│   ├── providers.tf          # NCP provider 설정
│   ├── variables.tf          # 변수 정의
│   ├── outputs.tf            # 출력값
│   ├── main.tf               # 루트 모듈 (모듈 조합)
│   └── modules/
│       ├── network/          # VPC, Subnet, Network ACL, Route Table
│       ├── compute/          # 서버 인스턴스, ACG, Init Script (cloud-init)
│       ├── security/         # SSL VPN, Auto Scaling Group
│       ├── lb/               # Application Load Balancer
│       ├── storage/          # NAS(NFS), Object Storage(media/static/backup)
│       └── cdn/              # Global Edge CDN
└── scripts/
    ├── install_webwas.sh     # Apache + Coursemos LMS 설치
    ├── install_db.sh         # MySQL 설치/설정
    ├── install_cache.sh      # Redis 설치/설정
    └── setup_dev.sh          # Jenkins CI/CD 환경 구성
```

---

## 배포

### 사전 준비

```bash
export NCLOUD_ACCESS_KEY="your-access-key"
export NCLOUD_SECRET_KEY="your-secret-key"
export NCLOUD_REGION="KR"
```

### Terraform 실행

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 출력값 확인

```bash
terraform output                                        # 전체 출력
terraform output -raw ssh_private_key > hoseo-lms.pem  # SSH 키 저장
chmod 600 hoseo-lms.pem
```

---

## apply 후 NCP 콘솔 수동 설정

NCP Terraform 프로바이더 미지원으로 콘솔에서 수동 처리가 필요한 항목입니다.

### ACG 서버 연결
> Server > 서버 선택 > ACG 관리

| 서버 | 연결할 ACG |
|------|-----------|
| hoseo-lms-webwas-1, -2 | hoseo-lms-acg-webwas |
| hoseo-lms-cache | hoseo-lms-acg-cache |
| hoseo-lms-db | hoseo-lms-acg-db |
| hoseo-lms-dev | hoseo-lms-acg-dev |

### NAT Gateway
1. VPC > NAT Gateway > 생성 (`hoseo-lms-subnet-natgw` 서브넷 선택)
2. Route Table > `0.0.0.0/0 → NAT GW` 라우트 추가
3. App / Dev / DB 서브넷에 Route Table 연결

### Block Storage 추가 (KVM Gen3 Terraform 미지원)
> Server > Storage > Block Storage > 생성 후 서버 연결
- DB 서버: 500GB SSD
- Dev 서버: 200GB SSD

### ALB HTTPS 리스너
> Load Balancer > hoseo-lms-alb > SSL 인증서 등록 > HTTPS:443 리스너 추가

### Object Storage 백업 정책
> Object Storage > hoseo-lms-backup
- 버전 관리 활성화
- 수명주기 정책: 90일 후 Archive, 365일 후 삭제

### 스냅샷 (주 1회)
> Server > Storage > Block Storage > 스냅샷 생성

---

## NCP Gen3 KVM 제약사항

실제 구현 과정에서 확인된 NCP Terraform 프로바이더 제약사항입니다.

| 리소스 / 속성 | 제약 | 처리 방법 |
|--------------|------|-----------|
| `ncloud_block_storage` | KVM Gen3 미지원 (XEN Gen2 전용) | NCP 콘솔 수동 연결 |
| `ncloud_block_storage_snapshot` | `block_storage_instance_no` 필요 → KVM 불가 | NCP 콘솔 스냅샷 |
| `access_control_group_configuration_no_list` | VPC 환경 미지원 (Classic 전용) | NCP 콘솔 ACG 연결 |
| NAS `volume_name_postfix` | 영숫자만 허용 (하이픈·언더스코어 불가) | `replace()` 함수로 제거 |

---

## 보안 정책

- SSH 기본 포트 변경 (22 → 커스텀)
- 관리자 접근: SSL VPN 경유 후 내부망
- WAF 차단 정책 운영 (IPS 연동)
- SSL/HTTPS 전용 (HTTP 리다이렉트)
- 개인정보 DB 암호화 (KISA 인정 알고리즘)
- 서브넷별 Network ACL + ACG 이중 방화벽

---

## SLA

| 항목 | 기준 |
|------|------|
| 장애 대응 | 통보 후 2시간 내 착수, 12시간 내 복구 |
| 가용성 | 24×365 무중단 |
| 동시 사용자 | 3,500명 이상 |
| 응답시간 | 3초 이내 |
| CPU 사용률 | 90% 미만 |
| Memory 사용률 | 75% 미만 |
