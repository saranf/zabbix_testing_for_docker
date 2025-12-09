#!/bin/bash

#############################################
# Zabbix Docker 제거 스크립트
#############################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    log_error "이 스크립트는 root 권한이 필요합니다. 'sudo ./uninstall.sh'로 실행하세요."
    exit 1
fi

log_warn "=========================================="
log_warn "  Zabbix 제거 스크립트"
log_warn "=========================================="
log_warn "이 스크립트는 다음을 제거합니다:"
log_warn "  - Zabbix Docker 컨테이너"
log_warn "  - Zabbix Docker 볼륨 (데이터 포함)"
log_warn "  - Nginx 설정"
log_warn ""

read -p "정말로 제거하시겠습니까? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_info "제거가 취소되었습니다."
    exit 0
fi

# Docker 컨테이너 및 볼륨 제거
log_info "Zabbix Docker 컨테이너 중지 및 제거 중..."
if [ -f "docker-compose.yml" ]; then
    docker-compose down -v
    log_info "Docker 컨테이너 및 볼륨 제거 완료"
else
    log_warn "docker-compose.yml 파일을 찾을 수 없습니다."
fi

# Nginx 설정 제거
log_info "Nginx 설정 제거 중..."
if [ -f "/etc/nginx/sites-enabled/zabbix" ]; then
    rm -f /etc/nginx/sites-enabled/zabbix
    log_info "Nginx 심볼릭 링크 제거 완료"
fi

if [ -f "/etc/nginx/sites-available/zabbix" ]; then
    rm -f /etc/nginx/sites-available/zabbix
    log_info "Nginx 설정 파일 제거 완료"
fi

# Nginx 재시작
if command -v nginx &> /dev/null; then
    systemctl restart nginx
    log_info "Nginx 재시작 완료"
fi

# SSL 인증서 제거 여부 확인
read -p "SSL 인증서도 제거하시겠습니까? (yes/no): " REMOVE_SSL

if [ "$REMOVE_SSL" == "yes" ]; then
    read -p "도메인을 입력하세요 (예: zabbix.rmstudio.co.kr): " DOMAIN
    if [ -n "$DOMAIN" ]; then
        log_info "SSL 인증서 제거 중..."
        certbot delete --cert-name $DOMAIN
        log_info "SSL 인증서 제거 완료"
    fi
fi

log_info "=========================================="
log_info "제거가 완료되었습니다!"
log_info "=========================================="
log_info ""
log_info "Docker와 Nginx는 제거되지 않았습니다."
log_info "필요시 수동으로 제거하세요:"
log_info "  sudo apt remove docker-ce docker-ce-cli containerd.io nginx"
log_info ""

