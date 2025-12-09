#!/bin/bash

#############################################
# SSL 인증서 자동 갱신 설정 스크립트
#############################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root 권한 체크
if [ "$EUID" -ne 0 ]; then 
    log_error "이 스크립트는 root 권한이 필요합니다. 'sudo ./setup-ssl-renewal.sh'로 실행하세요."
    exit 1
fi

log_info "SSL 인증서 자동 갱신 설정 중..."

# Certbot이 설치되어 있는지 확인
if ! command -v certbot &> /dev/null; then
    log_error "Certbot이 설치되어 있지 않습니다."
    exit 1
fi

# 갱신 테스트
log_info "SSL 인증서 갱신 테스트 중..."
if certbot renew --dry-run; then
    log_info "갱신 테스트 성공!"
else
    log_error "갱신 테스트 실패. Certbot 설정을 확인하세요."
    exit 1
fi

# Cron job 설정 (매일 오전 3시에 갱신 체크)
CRON_JOB="0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'"

# 기존 cron job 확인
if crontab -l 2>/dev/null | grep -q "certbot renew"; then
    log_info "SSL 자동 갱신 cron job이 이미 설정되어 있습니다."
else
    # Cron job 추가
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_info "SSL 자동 갱신 cron job이 추가되었습니다."
    log_info "매일 오전 3시에 인증서 갱신을 확인합니다."
fi

# Systemd timer 확인 (최신 시스템)
if systemctl list-timers 2>/dev/null | grep -q "certbot"; then
    log_info "Certbot systemd timer가 활성화되어 있습니다."
    systemctl status certbot.timer --no-pager
fi

log_info "=========================================="
log_info "SSL 인증서 자동 갱신 설정 완료!"
log_info "=========================================="
log_info ""
log_info "인증서는 만료 30일 전부터 자동으로 갱신됩니다."
log_info ""
log_info "수동 갱신 명령어:"
log_info "  sudo certbot renew"
log_info ""
log_info "인증서 상태 확인:"
log_info "  sudo certbot certificates"
log_info ""

