# 🚀 여기서 시작하세요!

Zabbix Docker 설치 프로젝트에 오신 것을 환영합니다!

---

## ⚡ 빠른 설치 (3단계)

### 1️⃣ 시스템 체크 (선택사항)
```bash
sudo ./check-requirements.sh
```

### 2️⃣ 자동 설치 실행
```bash
sudo ./install.sh
```

### 3️⃣ 접속
```
https://zabbix.rmstudio.co.kr
Username: Admin
Password: zabbix
```

**⚠️ 첫 로그인 후 즉시 비밀번호를 변경하세요!**

---

## 📚 문서 가이드

### 처음 사용하시나요?
👉 **[QUICKSTART.md](QUICKSTART.md)** - 빠른 시작 가이드

### 상세한 설치 및 사용법이 필요하신가요?
👉 **[README.md](README.md)** - 완전한 설치 및 사용 가이드

### 보안 설정이 궁금하신가요?
👉 **[SECURITY.md](SECURITY.md)** - 보안 설정 상세 가이드

### 시스템 구조가 궁금하신가요?
👉 **[ARCHITECTURE.md](ARCHITECTURE.md)** - 아키텍처 문서

---

## 🛠️ 주요 스크립트

| 스크립트 | 설명 | 사용법 |
|---------|------|--------|
| `install.sh` | 전체 자동 설치 | `sudo ./install.sh` |
| `check-requirements.sh` | 시스템 요구사항 체크 | `sudo ./check-requirements.sh` |
| `test-security.sh` | 보안 설정 테스트 | `./test-security.sh` |
| `setup-ssl-renewal.sh` | SSL 자동 갱신 설정 | `sudo ./setup-ssl-renewal.sh` |
| `uninstall.sh` | 완전 제거 | `sudo ./uninstall.sh` |

---

## 🔐 보안 기능

✅ **HTTPS/TLS 1.2+ 강제**  
✅ **보안 헤더** (HSTS, CSP, X-Frame-Options 등)  
✅ **Rate Limiting** (DDoS 방지)  
✅ **브루트포스 공격 방지** (로그인 제한)  
✅ **SSL 자동 갱신**  
✅ **네트워크 격리** (Docker)  
✅ **파일 접근 제어**  
✅ **서버 정보 숨김**  

---

## 📋 시스템 구성

```
Internet → Nginx (보안 프록시) → Zabbix Web → Zabbix Server → PostgreSQL
                                                    ↓
                                              Zabbix Agent
```

**컨테이너**:
- `zabbix-reverse-proxy` - Nginx 리버스 프록시 (보안 강화)
- `zabbix-web` - Zabbix 웹 UI
- `zabbix-server` - Zabbix 서버
- `postgres-server` - PostgreSQL 데이터베이스
- `zabbix-agent` - 자체 모니터링
- `certbot` - SSL 인증서 관리

---

## 🎯 주요 특징

✅ **완전 자동화** - 한 번의 명령으로 모든 것 설치  
✅ **Docker 기반** - 격리된 환경, 쉬운 관리  
✅ **보안 강화** - 업계 표준 보안 설정  
✅ **SSL 자동 발급** - Let's Encrypt 무료 인증서  
✅ **자동 갱신** - SSL 인증서 자동 갱신  
✅ **상세한 문서** - 설치부터 보안까지  

---

## 🔧 설치 후 할 일

### 1. 비밀번호 변경 (필수!)

#### Zabbix Admin
1. Zabbix 웹 UI 로그인
2. Administration → Users → Admin
3. Password 탭에서 변경

#### 데이터베이스
`.env` 파일 수정:
```bash
POSTGRES_PASSWORD=your_very_strong_password
```

재시작:
```bash
docker-compose down && docker-compose up -d
```

### 2. 방화벽 설정
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10847/tcp
sudo ufw enable
```

### 3. 보안 테스트
```bash
./test-security.sh
```

---

## 📊 유용한 명령어

### 상태 확인
```bash
docker-compose ps
```

### 로그 확인
```bash
docker-compose logs -f
docker-compose logs -f zabbix-reverse-proxy
docker-compose logs -f zabbix-server
```

### 재시작
```bash
docker-compose restart
```

### 중지
```bash
docker-compose down
```

### 완전 제거
```bash
sudo ./uninstall.sh
```

---

## ❓ 문제 해결

### 설치 중 오류
```bash
# 로그 확인
docker-compose logs

# 재설치
sudo ./uninstall.sh
sudo ./install.sh
```

### 웹 페이지 접속 불가
```bash
# 컨테이너 상태 확인
docker-compose ps

# Nginx 로그 확인
docker-compose logs zabbix-reverse-proxy
```

### SSL 인증서 오류
```bash
# 인증서 재발급
docker-compose run --rm certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email your@email.com \
    --agree-tos \
    -d zabbix.rmstudio.co.kr
```

---

## 🌐 접속 정보

- **URL**: https://zabbix.rmstudio.co.kr
- **Username**: Admin
- **Password**: zabbix (⚠️ 즉시 변경!)

---

## 📞 도움이 필요하신가요?

1. **[QUICKSTART.md](QUICKSTART.md)** - 빠른 시작 가이드
2. **[README.md](README.md)** - 상세 가이드
3. **[SECURITY.md](SECURITY.md)** - 보안 설정
4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - 시스템 구조

---

## 🎉 설치 완료 후

1. ✅ 비밀번호 변경
2. ✅ 방화벽 설정
3. ✅ 보안 테스트 실행
4. ✅ 첫 호스트 추가
5. ✅ 모니터링 시작!

**즐거운 모니터링 되세요!** 🚀

