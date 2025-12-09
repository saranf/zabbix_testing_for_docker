#!/bin/bash

#############################################
# Zabbix Docker 자동 설치 스크립트
# - Docker & Docker Compose 설치
# - Nginx 설치 및 설정
# - SSL 인증서 발급 (Let's Encrypt)
# - Zabbix 실행
#############################################

set -e  # 에러 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root 권한 체크
if [ "$EUID" -ne 0 ]; then 
    log_error "이 스크립트는 root 권한이 필요합니다. 'sudo ./install.sh'로 실행하세요."
    exit 1
fi

# 도메인 입력 받기
read -p "도메인을 입력하세요 (기본값: zabbix.rmstudio.co.kr): " DOMAIN
DOMAIN=${DOMAIN:-zabbix.rmstudio.co.kr}

# 이메일 입력 받기 (SSL 인증서용)
read -p "SSL 인증서 발급을 위한 이메일을 입력하세요: " EMAIL

if [ -z "$EMAIL" ]; then
    log_error "이메일은 필수입니다."
    exit 1
fi

# SSL 설치 여부 확인
read -p "SSL 인증서를 설치하시겠습니까? (y/n, 기본값: y): " INSTALL_SSL
INSTALL_SSL=${INSTALL_SSL:-y}

log_info "=========================================="
log_info "Zabbix Docker 자동 설치 시작"
log_info "도메인: $DOMAIN"
log_info "이메일: $EMAIL"
log_info "SSL 설치: $INSTALL_SSL"
log_info "=========================================="

# 1. 시스템 업데이트
log_info "시스템 패키지 업데이트 중..."
apt-get update -qq

# 2. Docker 설치 확인 및 설치
if ! command -v docker &> /dev/null; then
    log_info "Docker 설치 중..."
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    log_info "Docker 설치 완료"
else
    log_info "Docker가 이미 설치되어 있습니다."
fi

# 3. Docker Compose 설치 확인 및 설치
if ! command -v docker-compose &> /dev/null; then
    log_info "Docker Compose 설치 중..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_info "Docker Compose 설치 완료"
else
    log_info "Docker Compose가 이미 설치되어 있습니다."
fi

# 4. certbot 디렉토리 생성
log_info "SSL 인증서 디렉토리 생성 중..."
mkdir -p certbot/conf certbot/www

# 5. 방화벽 컨테이너 빌드 및 실행
log_info "방화벽 컨테이너 빌드 중..."
docker-compose build zabbix-firewall

log_info "방화벽 컨테이너 실행 중..."
docker-compose up -d zabbix-firewall

# 방화벽 적용 대기
sleep 5

log_info "방화벽 규칙 적용 완료"

# 6. Zabbix Docker 컨테이너 실행 (Nginx 포함)
log_info "Zabbix Docker 컨테이너 실행 중..."
docker-compose up -d postgres-server zabbix-server zabbix-web zabbix-agent

# 컨테이너 시작 대기
log_info "Zabbix 서비스 시작 대기 중 (약 30초)..."
sleep 30

# 7. Nginx 리버스 프록시 설정
log_info "Nginx 리버스 프록시 설정 중..."

# 도메인을 nginx 설정 파일에 업데이트
sed -i "s/zabbix\.rmstudio\.co\.kr/$DOMAIN/g" nginx/conf.d/zabbix.conf
sed -i "s/zabbix\.rmstudio\.co\.kr/$DOMAIN/g" nginx/conf.d/default-http.conf

# Nginx 컨테이너 시작 (SSL 인증서 발급 전)
log_info "Nginx 컨테이너 시작 중..."
docker-compose up -d zabbix-reverse-proxy

# Nginx 시작 대기
sleep 5

log_info "Nginx 설정 완료"

# 8. SSL 인증서 설치
if [[ "$INSTALL_SSL" == "y" || "$INSTALL_SSL" == "Y" ]]; then
    log_info "SSL 인증서 발급 중..."

    # Certbot으로 SSL 인증서 발급
    docker-compose run --rm certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN

    if [ $? -eq 0 ]; then
        log_info "SSL 인증서 발급 완료"

        # HTTP 전용 설정 파일 비활성화
        mv nginx/conf.d/default-http.conf nginx/conf.d/default-http.conf.disabled

        # Nginx 재시작하여 HTTPS 설정 적용
        docker-compose restart zabbix-reverse-proxy

        # Certbot 자동 갱신 컨테이너 시작
        docker-compose up -d certbot

        log_info "SSL 인증서 설치 완료"
        log_info "자동 갱신이 설정되었습니다."
    else
        log_error "SSL 인증서 발급 실패"
        log_warn "HTTP로 계속 진행합니다."
    fi
else
    log_warn "SSL 인증서 설치를 건너뜁니다."
fi

log_info "=========================================="
log_info "설치가 완료되었습니다!"
log_info "=========================================="
log_info ""
log_info "접속 정보:"
if [[ "$INSTALL_SSL" == "y" || "$INSTALL_SSL" == "Y" ]]; then
    log_info "  URL: https://$DOMAIN"
else
    log_info "  URL: http://$DOMAIN"
fi
log_info ""
log_info "Zabbix 로그인 정보:"
log_info "  Username: Admin"
log_info "  Password: zabbix"
log_info ""
log_warn "⚠️  보안을 위해 첫 로그인 후 반드시 비밀번호를 변경하세요!"
log_info ""
log_info "적용된 보안 설정:"
log_info "  ✓ Docker 방화벽 (iptables)"
log_info "  ✓ HTTPS/TLS 1.2+ 강제"
log_info "  ✓ 보안 헤더 (HSTS, CSP, X-Frame-Options 등)"
log_info "  ✓ Rate Limiting (DDoS 방지)"
log_info "  ✓ SSL/TLS 최신 암호화 스위트"
log_info "  ✓ OCSP Stapling"
log_info "  ✓ 서버 정보 숨김"
log_info "  ✓ SSH 브루트포스 방지"
log_info "  ✓ Port Scanning 방지"
log_info ""
log_info "방화벽 상태 확인:"
log_info "  docker-compose logs zabbix-firewall"
log_info ""
log_info "유용한 명령어:"
log_info "  상태 확인: docker-compose ps"
log_info "  로그 확인: docker-compose logs -f"
log_info "  Nginx 로그: docker-compose logs -f zabbix-reverse-proxy"
log_info "  재시작: docker-compose restart"
log_info "  중지: docker-compose down"
log_info ""

