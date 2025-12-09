# Zabbix Docker Setup

Docker를 사용한 Zabbix 모니터링 시스템 구축 프로젝트입니다.

## 📋 구성 요소

- **Zabbix Server**: 모니터링 서버 (포트: 10847)
- **Zabbix Web UI**: 웹 인터페이스 (내부 포트: 8080)
- **PostgreSQL**: 데이터베이스 (내부 네트워크만)
- **Zabbix Agent**: 자체 모니터링용 에이전트
- **Nginx Reverse Proxy**: 보안 강화 리버스 프록시 (포트: 80, 443)
- **Certbot**: SSL 인증서 자동 발급 및 갱신
- **도메인**: zabbix.rmstudio.co.kr

## 🔐 보안 기능

- ✅ **HTTPS/TLS 1.2+ 강제** - 최신 암호화 프로토콜
- ✅ **보안 헤더** - HSTS, CSP, X-Frame-Options 등
- ✅ **Rate Limiting** - DDoS 및 브루트포스 공격 방지
- ✅ **SSL/TLS 최적화** - OCSP Stapling, Perfect Forward Secrecy
- ✅ **서버 정보 숨김** - 버전 정보 노출 방지
- ✅ **파일 접근 제어** - 민감한 파일 차단
- ✅ **네트워크 격리** - 데이터베이스 외부 접근 차단

자세한 내용은 [SECURITY.md](SECURITY.md)를 참고하세요.

## 🚀 빠른 시작 (자동 설치)

### 방법 1: 원클릭 자동 설치 (권장) ⭐

모든 것을 자동으로 설치합니다 (Docker, Nginx, SSL 인증서, Zabbix)

```bash
# 1. 저장소 클론 또는 파일 다운로드
cd zabbix_testing_for_docker

# 2. 설치 전 시스템 체크 (선택사항)
sudo ./check-requirements.sh

# 3. 자동 설치 실행
sudo ./install.sh
```

설치 중 입력 사항:
- **도메인**: zabbix.rmstudio.co.kr (기본값)
- **이메일**: SSL 인증서 발급용 이메일 주소
- **SSL 설치 여부**: y (권장)

### 방법 2: 수동 설치

#### 1. 사전 요구사항

- Docker 및 Docker Compose 설치
- 도메인 DNS 설정 (zabbix.rmstudio.co.kr → 서버 IP)

#### 2. 설치 및 실행

```bash
# 저장소 클론 또는 파일 다운로드
cd zabbix_testing_for_docker

# Docker Compose로 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

### 3. 접속 정보

- **도메인 접속**: https://zabbix.rmstudio.co.kr (SSL 설치 시)
- **HTTP 접속**: http://zabbix.rmstudio.co.kr (SSL 설치 전)

**기본 로그인 정보**:
- Username: `Admin`
- Password: `zabbix`

⚠️ **보안 주의**: 첫 로그인 후 반드시 비밀번호를 변경하세요!

### 4. 보안 설정 확인

설치 후 적용된 보안 설정을 확인하세요:

```bash
# 보안 헤더 확인
curl -I https://zabbix.rmstudio.co.kr

# SSL 등급 확인
# https://www.ssllabs.com/ssltest/
```

자세한 보안 설정은 [SECURITY.md](SECURITY.md)를 참고하세요.

## 📜 스크립트 설명

| 스크립트 | 설명 |
|---------|------|
| `install.sh` | 전체 자동 설치 (Docker, Nginx, SSL, Zabbix) |
| `check-requirements.sh` | 설치 전 시스템 요구사항 체크 |
| `setup-ssl-renewal.sh` | SSL 인증서 자동 갱신 설정 |
| `uninstall.sh` | Zabbix 완전 제거 |

## 🔧 Nginx 리버스 프록시 설정 (수동)

⚠️ **자동 설치 스크립트를 사용하면 이 과정이 자동으로 처리됩니다.**

도메인(zabbix.rmstudio.co.kr)으로 접속하려면 Nginx를 설정해야 합니다.

### Nginx 설치 (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install nginx -y
```

### 설정 파일 적용

```bash
# 설정 파일 복사
sudo cp nginx-reverse-proxy.conf /etc/nginx/sites-available/zabbix

# 심볼릭 링크 생성
sudo ln -s /etc/nginx/sites-available/zabbix /etc/nginx/sites-enabled/

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

## 🔒 SSL/HTTPS 설정 (수동)

⚠️ **자동 설치 스크립트를 사용하면 이 과정이 자동으로 처리됩니다.**

Let's Encrypt를 사용한 무료 SSL 인증서 발급:

```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx -y

# SSL 인증서 발급
sudo certbot --nginx -d zabbix.rmstudio.co.kr

# 자동 갱신 설정
sudo ./setup-ssl-renewal.sh
```

## 📊 포트 정보

| 서비스 | 포트 | 노출 | 설명 |
|--------|------|------|------|
| Nginx (HTTP) | 80 | 외부 | HTTP (HTTPS로 리다이렉트) |
| Nginx (HTTPS) | 443 | 외부 | HTTPS 웹 인터페이스 |
| Zabbix Server | 10847 | 외부 | Zabbix Agent 통신 포트 |
| Zabbix Web UI | 8080 | 내부 | 웹 인터페이스 (Nginx를 통해서만 접근) |
| PostgreSQL | 5432 | 내부 | 데이터베이스 (내부 네트워크만) |

**보안**: 데이터베이스와 웹 UI는 내부 Docker 네트워크에만 노출되어 외부에서 직접 접근할 수 없습니다.

## 🛠️ 유용한 명령어

### Docker 관리

```bash
# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f zabbix-server
docker-compose logs -f zabbix-web

# 컨테이너 재시작
docker-compose restart

# 중지
docker-compose down

# 완전 삭제 (데이터 포함)
docker-compose down -v
```

### SSL 인증서 관리

```bash
# 인증서 상태 확인
sudo certbot certificates

# 수동 갱신
sudo certbot renew

# 갱신 테스트
sudo certbot renew --dry-run
```

### 제거

```bash
# Zabbix 완전 제거
sudo ./uninstall.sh
```

## 🔐 보안 설정

### 1. 데이터베이스 비밀번호 변경 (필수!)

`.env` 파일에서 `POSTGRES_PASSWORD`를 변경하세요:

```env
POSTGRES_PASSWORD=your_very_strong_password_here_2024!
```

변경 후 재시작:
```bash
docker-compose down
docker-compose up -d
```

### 2. Zabbix Admin 비밀번호 변경 (필수!)

1. Zabbix 웹 UI 로그인
2. Administration → Users → Admin 선택
3. Password 탭에서 비밀번호 변경

### 3. 방화벽 설정

```bash
# UFW 사용 시
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 10847/tcp  # Zabbix Server (Agent 통신용)
sudo ufw enable
```

### 4. 추가 보안 설정

자세한 보안 설정 및 권장사항은 [SECURITY.md](SECURITY.md)를 참고하세요:
- SSL/TLS 보안 설정
- 보안 헤더 상세 설명
- Rate Limiting 설정
- 로그 모니터링
- 백업 전략

## 📝 환경 변수 (.env)

| 변수 | 기본값 | 설명 |
|------|--------|------|
| POSTGRES_USER | zabbix | DB 사용자명 |
| POSTGRES_PASSWORD | zabbix_secure_password_2024 | DB 비밀번호 ⚠️ 변경 필수! |
| POSTGRES_DB | zabbix | DB 이름 |
| ZABBIX_SERVER_PORT | 10847 | Zabbix 서버 포트 |
| TIMEZONE | Asia/Seoul | 시간대 |
| ZBX_SERVER_NAME | Zabbix Monitoring Server | 서버 이름 |

## 🐛 문제 해결

### 컨테이너가 시작되지 않을 때

```bash
# 로그 확인
docker-compose logs

# 컨테이너 재생성
docker-compose down
docker-compose up -d
```

### 데이터베이스 연결 오류

```bash
# PostgreSQL 컨테이너 상태 확인
docker-compose ps postgres-server

# PostgreSQL 로그 확인
docker-compose logs postgres-server
```

### 웹 UI 접속 불가

```bash
# Zabbix Web 컨테이너 로그 확인
docker-compose logs zabbix-web

# 포트 사용 확인
sudo netstat -tulpn | grep 8847
```

## 📚 참고 자료

- [Zabbix 공식 문서](https://www.zabbix.com/documentation/current/)
- [Zabbix Docker Hub](https://hub.docker.com/u/zabbix)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [보안 설정 가이드](SECURITY.md)
- [빠른 시작 가이드](QUICKSTART.md)

## 📄 라이선스

이 프로젝트는 Zabbix의 GPL v2 라이선스를 따릅니다.

---

## 🎯 주요 특징 요약

✅ **완전 자동화 설치** - 한 번의 명령으로 모든 것 설치
✅ **Docker 기반** - 격리된 환경, 쉬운 관리
✅ **보안 강화** - 업계 표준 보안 설정 적용
✅ **SSL 자동 발급** - Let's Encrypt 무료 인증서
✅ **자동 갱신** - SSL 인증서 자동 갱신
✅ **Rate Limiting** - DDoS 및 브루트포스 방지
✅ **상세한 문서** - 설치부터 보안까지 완벽 가이드

**지금 바로 시작하세요**: `sudo ./install.sh` 🚀

