# 🚀 Zabbix 빠른 시작 가이드

## 단 3단계로 Zabbix 설치하기!

### 📋 준비사항

1. **Ubuntu/Debian 서버** (최소 1GB RAM, 10GB 디스크)
2. **도메인 DNS 설정**: `zabbix.rmstudio.co.kr` A 레코드를 서버 IP로 설정
3. **Root 또는 sudo 권한**

---

## ⚡ 3단계 설치

### 1️⃣ 파일 다운로드

```bash
git clone <repository-url>
cd zabbix_testing_for_docker
```

또는 파일을 직접 업로드하세요.

### 2️⃣ 시스템 체크 (선택사항)

```bash
sudo ./check-requirements.sh
```

이 명령어는 다음을 확인합니다:
- ✅ 메모리 및 디스크 공간
- ✅ 포트 사용 여부 (80, 443, 8847, 10847)
- ✅ 네트워크 연결
- ✅ 필수 패키지

### 3️⃣ 자동 설치 실행

```bash
sudo ./install.sh
```

**설치 중 입력 사항:**

```
도메인을 입력하세요 (기본값: zabbix.rmstudio.co.kr): [Enter]
SSL 인증서 발급을 위한 이메일을 입력하세요: your@email.com
SSL 인증서를 설치하시겠습니까? (y/n, 기본값: y): y
```

**설치 시간**: 약 5-10분

---

## ✅ 설치 완료!

설치가 완료되면 다음과 같은 메시지가 표시됩니다:

```
==========================================
설치가 완료되었습니다!
==========================================

접속 정보:
  URL: https://zabbix.rmstudio.co.kr
  로컬: http://localhost:8847

Zabbix 로그인 정보:
  Username: Admin
  Password: zabbix

⚠️  보안을 위해 첫 로그인 후 반드시 비밀번호를 변경하세요!
```

---

## 🌐 접속하기

1. 브라우저에서 `https://zabbix.rmstudio.co.kr` 접속
2. 로그인:
   - Username: `Admin`
   - Password: `zabbix`
3. **즉시 비밀번호 변경!**
   - Administration → Users → Admin → Password 탭

---

## 🔧 자동 설치 스크립트가 하는 일

`install.sh` 스크립트는 다음을 자동으로 수행합니다:

1. ✅ **시스템 업데이트**
2. ✅ **Docker 설치** (미설치 시)
3. ✅ **Docker Compose 설치** (미설치 시)
4. ✅ **Zabbix Docker 컨테이너 실행**
   - PostgreSQL 데이터베이스
   - Zabbix Server
   - Zabbix Web UI
   - Zabbix Agent
5. ✅ **Nginx 리버스 프록시 컨테이너 실행** (보안 강화)
6. ✅ **SSL 인증서 발급** (Let's Encrypt)
7. ✅ **SSL 자동 갱신 설정**
8. ✅ **보안 설정 적용**
   - HTTPS 강제
   - 보안 헤더 (HSTS, CSP, X-Frame-Options 등)
   - Rate Limiting (DDoS 방지)
   - 파일 접근 제어

---

## 🛠️ 설치 후 확인

### 컨테이너 상태 확인

```bash
docker-compose ps
```

모든 컨테이너가 `Up` 상태여야 합니다:

```
NAME                STATUS
zabbix-postgres     Up
zabbix-server       Up (healthy)
zabbix-web          Up (healthy)
zabbix-agent        Up
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f zabbix-server
docker-compose logs -f zabbix-web
```

### SSL 인증서 확인

```bash
sudo certbot certificates
```

---

## ❓ 문제 해결

### 설치 중 오류 발생

```bash
# 로그 확인
docker-compose logs

# 재설치
sudo ./uninstall.sh
sudo ./install.sh
```

### 웹 페이지 접속 불가

1. **컨테이너 상태 확인**
   ```bash
   docker-compose ps
   ```

2. **Nginx 상태 확인**
   ```bash
   sudo systemctl status nginx
   ```

3. **방화벽 확인**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### SSL 인증서 오류

```bash
# 인증서 재발급
sudo certbot --nginx -d zabbix.rmstudio.co.kr --force-renewal
```

---

## 🗑️ 제거

Zabbix를 완전히 제거하려면:

```bash
sudo ./uninstall.sh
```

이 명령어는 다음을 제거합니다:
- Docker 컨테이너 및 볼륨
- Nginx 설정
- SSL 인증서 (선택)

---

## 📚 다음 단계

1. **비밀번호 변경** (필수!)
2. **호스트 추가**: Configuration → Hosts → Create host
3. **모니터링 설정**: 템플릿 적용 및 트리거 설정
4. **알림 설정**: Administration → Media types

자세한 내용은 [README.md](README.md)를 참고하세요.

---

## 💡 팁

- **백업**: 정기적으로 PostgreSQL 데이터베이스 백업
- **모니터링**: Zabbix 자체도 모니터링 (Zabbix Agent 포함)
- **업데이트**: Docker 이미지 정기 업데이트
  ```bash
  docker-compose pull
  docker-compose up -d
  ```
- **보안 테스트**: 설치 후 보안 설정 확인
  ```bash
  ./test-security.sh
  ```

---

## 🔐 보안 확인

설치 후 보안 설정을 테스트하세요:

```bash
# 자동 보안 테스트
./test-security.sh

# 수동 확인
curl -I https://zabbix.rmstudio.co.kr
```

자세한 보안 설정은 [SECURITY.md](SECURITY.md)를 참고하세요.

---

**문제가 있나요?** [README.md](README.md)의 문제 해결 섹션을 확인하세요!

