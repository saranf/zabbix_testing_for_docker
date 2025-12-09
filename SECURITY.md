# 🔐 보안 설정 가이드

이 문서는 Zabbix Docker 설치에 적용된 보안 설정을 설명합니다.

## 📋 적용된 보안 설정 목록

### 1. Docker 방화벽 (iptables)

#### ✅ 포트 기반 접근 제어

**허용된 포트**:
- **22** (SSH) - 브루트포스 방지 (1분에 4회 제한)
- **80** (HTTP) - Rate Limiting (분당 100회)
- **443** (HTTPS) - Rate Limiting (분당 100회)
- **10847** (Zabbix Server) - Agent 통신용

**기본 정책**:
- INPUT: DROP (모든 입력 차단, 허용된 포트만 예외)
- FORWARD: DROP (포워딩 차단)
- OUTPUT: ACCEPT (출력 허용)

#### ✅ SSH 브루트포스 방지

```bash
# 1분에 4회 이상 SSH 연결 시도 시 차단
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
```

#### ✅ DDoS 공격 방지

**SYN Flood 방지**:
```bash
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
```

**HTTP/HTTPS Rate Limiting**:
```bash
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
```

#### ✅ Port Scanning 방지

```bash
iptables -N port-scanning
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A port-scanning -j DROP
```

#### ✅ 악의적 패킷 차단

- **Invalid 패킷 차단**: 비정상적인 상태의 패킷 필터링
- **Fragmented 패킷 차단**: 조각난 패킷 차단
- **XMAS 패킷 차단**: 모든 플래그가 설정된 패킷 차단
- **NULL 패킷 차단**: 플래그가 없는 패킷 차단

#### ✅ 방화벽 관리

```bash
# 방화벽 상태 확인
./firewall-manage.sh status

# 방화벽 규칙 확인
./firewall-manage.sh rules

# 방화벽 로그 확인
./firewall-manage.sh logs

# 방화벽 재시작
./firewall-manage.sh restart
```

---

### 2. SSL/TLS 보안

#### ✅ 강력한 암호화 프로토콜
- **TLS 1.2 및 TLS 1.3만 허용** (TLS 1.0, 1.1 비활성화)
- **최신 암호화 스위트 사용** (ECDHE, AES-GCM, ChaCha20-Poly1305)
- **Perfect Forward Secrecy (PFS)** 지원

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...';
```

#### ✅ OCSP Stapling
- SSL 인증서 유효성 검증 성능 향상
- 프라이버시 보호 강화

```nginx
ssl_stapling on;
ssl_stapling_verify on;
```

#### ✅ SSL 세션 관리
- 세션 캐시 최적화
- 세션 티켓 비활성화 (보안 강화)

---

### 3. 보안 헤더

#### ✅ HSTS (HTTP Strict Transport Security)
- **2년간 HTTPS 강제**
- 서브도메인 포함
- HSTS Preload 지원

```nginx
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

#### ✅ X-Frame-Options
- **클릭재킹 공격 방지**
- 동일 출처에서만 iframe 허용

```nginx
X-Frame-Options: SAMEORIGIN
```

#### ✅ X-Content-Type-Options
- **MIME 타입 스니핑 방지**
- XSS 공격 벡터 차단

```nginx
X-Content-Type-Options: nosniff
```

#### ✅ X-XSS-Protection
- **브라우저 XSS 필터 활성화**

```nginx
X-XSS-Protection: 1; mode=block
```

#### ✅ Content Security Policy (CSP)
- **XSS 및 데이터 주입 공격 방지**
- 허용된 리소스 출처 제한

```nginx
Content-Security-Policy: default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; ...
```

#### ✅ Referrer-Policy
- **민감한 정보 유출 방지**

```nginx
Referrer-Policy: strict-origin-when-cross-origin
```

#### ✅ Permissions-Policy
- **브라우저 기능 접근 제한**
- 위치정보, 마이크, 카메라 비활성화

```nginx
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

---

### 4. Rate Limiting (Nginx - 애플리케이션 레벨)

#### ✅ 일반 요청 제한
- **초당 10개 요청** 제한
- 버스트: 20개 요청

```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req zone=general burst=20 nodelay;
```

#### ✅ 로그인 요청 제한
- **분당 5개 로그인 시도** 제한
- 브루트포스 공격 방지

```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req zone=login burst=5 nodelay;
```

#### ✅ 동시 연결 제한
- **IP당 최대 10개 동시 연결**

```nginx
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_conn addr 10;
```

---

### 5. 서버 정보 보호

#### ✅ 서버 버전 숨김
```nginx
server_tokens off;
```

#### ✅ 프록시 헤더 제거
```nginx
proxy_hide_header X-Powered-By;
```

---

### 6. 요청 크기 및 타임아웃 제한

#### ✅ 클라이언트 요청 크기 제한
- **최대 업로드 크기: 10MB**
- 대용량 파일 업로드 공격 방지

```nginx
client_max_body_size 10M;
client_body_buffer_size 128k;
```

#### ✅ 타임아웃 설정
- **연결 타임아웃: 12초**
- **전송 타임아웃: 10초**
- Slowloris 공격 방지

```nginx
client_body_timeout 12;
client_header_timeout 12;
send_timeout 10;
```

---

### 7. 파일 접근 제어

#### ✅ 숨겨진 파일 차단
```nginx
location ~ /\. {
    deny all;
}
```

#### ✅ 민감한 파일 차단
- `.conf`, `.sql`, `.bak`, `.log` 등 차단

```nginx
location ~* \.(conf|sql|bak|backup|old|log)$ {
    deny all;
}
```

---

### 8. 데이터베이스 보안

#### ✅ 네트워크 격리
- PostgreSQL은 **내부 Docker 네트워크에만 노출**
- 외부 접근 불가

#### ✅ 강력한 비밀번호
- `.env` 파일에서 비밀번호 변경 필수

---

### 9. Docker 보안

#### ✅ 읽기 전용 설정 파일
```yaml
volumes:
  - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./nginx/conf.d:/etc/nginx/conf.d:ro
```

#### ✅ 자동 재시작
```yaml
restart: unless-stopped
```

#### ✅ Health Check
- 모든 컨테이너에 헬스체크 설정
- 자동 복구 메커니즘

---

## 🛡️ 추가 보안 권장사항

### 1. 비밀번호 변경 (필수!)

#### Zabbix Admin 비밀번호
1. Zabbix 웹 UI 로그인
2. Administration → Users → Admin
3. Password 탭에서 변경

#### 데이터베이스 비밀번호
`.env` 파일 수정:
```bash
POSTGRES_PASSWORD=your_very_strong_password_here
```

변경 후 재시작:
```bash
docker-compose down
docker-compose up -d
```

---

### 2. 방화벽 확인

**Docker 방화벽이 자동으로 설정됩니다!**

```bash
# 방화벽 상태 확인
./firewall-manage.sh status

# 방화벽 규칙 확인
./firewall-manage.sh rules

# 방화벽 로그 확인
./firewall-manage.sh logs
```

#### 추가 시스템 방화벽 (선택사항)

**UFW (Ubuntu)**:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 10847/tcp # Zabbix Server
sudo ufw enable
```

**iptables (수동 설정 시)**:
```bash
# 기본 정책
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 허용 규칙
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 저장
iptables-save > /etc/iptables/rules.v4
```

---

### 3. SSH 보안 강화

```bash
# /etc/ssh/sshd_config 수정
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222  # 기본 포트 변경

# SSH 재시작
sudo systemctl restart sshd
```

---

### 4. 정기 업데이트

#### Docker 이미지 업데이트
```bash
docker-compose pull
docker-compose up -d
```

#### 시스템 업데이트
```bash
sudo apt update && sudo apt upgrade -y
```

---

### 5. 로그 모니터링

#### Nginx 로그 확인
```bash
docker-compose logs -f zabbix-reverse-proxy
```

#### 실패한 로그인 시도 확인
```bash
docker-compose exec zabbix-web cat /var/log/nginx/zabbix_error.log | grep "limit_req"
```

---

### 6. 백업

#### 데이터베이스 백업
```bash
docker-compose exec postgres-server pg_dump -U zabbix zabbix > backup_$(date +%Y%m%d).sql
```

#### 설정 파일 백업
```bash
tar -czf zabbix_config_backup_$(date +%Y%m%d).tar.gz \
    docker-compose.yml .env nginx/ certbot/
```

---

## 🔍 보안 테스트

### SSL 테스트
```bash
# SSL Labs 테스트
https://www.ssllabs.com/ssltest/analyze.html?d=zabbix.rmstudio.co.kr

# 로컬 테스트
openssl s_client -connect zabbix.rmstudio.co.kr:443 -tls1_2
```

### 보안 헤더 테스트
```bash
curl -I https://zabbix.rmstudio.co.kr
```

### Rate Limiting 테스트
```bash
# 연속 요청 테스트
for i in {1..30}; do curl -I https://zabbix.rmstudio.co.kr; done
```

---

## 📚 참고 자료

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Security Headers](https://securityheaders.com/)
- [Nginx Security Best Practices](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)

---

## ⚠️ 보안 사고 대응

보안 사고 발견 시:
1. 즉시 서비스 중지: `docker-compose down`
2. 로그 백업 및 분석
3. 비밀번호 변경
4. 시스템 재설치 고려

