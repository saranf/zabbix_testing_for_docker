# 🔧 포트 설정 가이드

## 📋 개요

모든 포트는 `.env` 파일에서 중앙 관리되며, 변경 시 방화벽 규칙도 자동으로 적용됩니다.

---

## ⚙️ 기본 포트 설정

`.env` 파일:

```env
#############################################
# 포트 설정 (원하는 포트로 변경 가능)
#############################################

# HTTP/HTTPS 포트
HTTP_PORT=80
HTTPS_PORT=443

# Zabbix Server 포트 (Agent 통신용)
ZABBIX_SERVER_PORT=10847

# SSH 포트 (방화벽 설정용)
SSH_PORT=22
```

---

## 🔄 포트 변경 방법

### 1단계: .env 파일 수정

```bash
vi .env
```

원하는 포트로 변경:
```env
HTTP_PORT=8080
HTTPS_PORT=8443
ZABBIX_SERVER_PORT=20051
SSH_PORT=2222
```

### 2단계: 컨테이너 재시작

```bash
docker-compose down
docker-compose up -d
```

### 3단계: 방화벽 규칙 확인

```bash
# 방화벽 규칙 확인 (자동으로 새 포트 적용됨)
./firewall-manage.sh rules

# 포트 테스트
./firewall-manage.sh test
```

---

## 📊 포트 사용 현황

| 포트 변수 | 기본값 | 용도 | 외부 노출 |
|-----------|--------|------|-----------|
| `HTTP_PORT` | 80 | HTTP (HTTPS 리다이렉트) | ✅ |
| `HTTPS_PORT` | 443 | HTTPS (웹 UI) | ✅ |
| `ZABBIX_SERVER_PORT` | 10847 | Zabbix Agent 통신 | ✅ |
| `SSH_PORT` | 22 | SSH 접속 | ✅ |
| - | 8080 | Zabbix Web (내부) | ❌ |
| - | 5432 | PostgreSQL (내부) | ❌ |
| - | 10051 | Zabbix Server (내부) | ❌ |

---

## 🔐 방화벽 자동 적용

포트를 변경하면 다음 방화벽 규칙이 자동으로 적용됩니다:

### SSH 포트
```bash
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT
```
- **브루트포스 방지**: 1분에 4회 이상 시도 시 차단

### HTTP 포트
```bash
iptables -A INPUT -p tcp --dport $HTTP_PORT -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
```
- **Rate Limiting**: 분당 100회 제한

### HTTPS 포트
```bash
iptables -A INPUT -p tcp --dport $HTTPS_PORT -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
```
- **Rate Limiting**: 분당 100회 제한

### Zabbix Server 포트
```bash
iptables -A INPUT -p tcp --dport $ZABBIX_SERVER_PORT -j ACCEPT
```
- **Agent 통신**: 제한 없음

---

## ⚠️ 주의사항

### 1. 권한 문제
- **1024 이하 포트**: root 권한 필요
- **권장**: 1024 이상의 포트 사용 (예: 8080, 8443)

### 2. 포트 충돌
다른 서비스와 포트 충돌 확인:
```bash
# 포트 사용 확인
sudo netstat -tuln | grep :80
sudo ss -tuln | grep :80

# 또는
sudo lsof -i :80
```

### 3. 방화벽 설정
외부 방화벽(클라우드 보안 그룹 등)도 함께 변경:
```bash
# AWS Security Group
# GCP Firewall Rules
# Azure NSG
```

### 4. DNS 설정
포트를 기본값(80, 443)이 아닌 값으로 변경 시:
- URL에 포트 번호 포함 필요: `https://zabbix.rmstudio.co.kr:8443`
- 또는 외부 로드밸런서/프록시 사용

---

## 🧪 포트 테스트

### 로컬 테스트
```bash
# HTTP 포트 테스트
curl -I http://localhost:${HTTP_PORT}

# HTTPS 포트 테스트
curl -I https://localhost:${HTTPS_PORT}

# Zabbix Server 포트 테스트
telnet localhost ${ZABBIX_SERVER_PORT}
```

### 외부 테스트
```bash
# 외부에서 접근 테스트
curl -I http://your-server-ip:${HTTP_PORT}
curl -I https://your-domain:${HTTPS_PORT}
```

### 방화벽 테스트
```bash
# 방화벽 규칙 확인
./firewall-manage.sh rules

# 포트 상태 확인
./firewall-manage.sh test
```

---

## 📝 예제: 비표준 포트 사용

### 시나리오
포트 80, 443이 이미 사용 중인 경우

### 설정
`.env` 파일:
```env
HTTP_PORT=8080
HTTPS_PORT=8443
ZABBIX_SERVER_PORT=20051
SSH_PORT=22
```

### 접속
```
http://zabbix.rmstudio.co.kr:8080
https://zabbix.rmstudio.co.kr:8443
```

### Nginx 리버스 프록시 (선택사항)
외부 Nginx로 80/443 → 8080/8443 프록시:

```nginx
server {
    listen 80;
    server_name zabbix.rmstudio.co.kr;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}

server {
    listen 443 ssl;
    server_name zabbix.rmstudio.co.kr;
    
    location / {
        proxy_pass https://localhost:8443;
    }
}
```

---

## 🔍 문제 해결

### 포트 변경이 적용되지 않음
```bash
# 컨테이너 완전 재시작
docker-compose down
docker-compose up -d

# 방화벽 재시작
docker-compose restart zabbix-firewall
```

### 방화벽 규칙 확인
```bash
# 현재 규칙 확인
./firewall-manage.sh rules

# 로그 확인
./firewall-manage.sh logs
```

### 포트 충돌 해결
```bash
# 포트 사용 프로세스 확인
sudo lsof -i :80

# 프로세스 종료
sudo kill -9 <PID>
```

---

## 📚 관련 문서

- [README.md](README.md) - 전체 설치 가이드
- [ARCHITECTURE.md](ARCHITECTURE.md) - 시스템 아키텍처
- [SECURITY.md](SECURITY.md) - 보안 설정
- [START_HERE.md](START_HERE.md) - 빠른 시작 가이드

