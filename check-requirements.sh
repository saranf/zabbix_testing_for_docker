#!/bin/bash

#############################################
# Zabbix 설치 전 시스템 요구사항 체크 스크립트
#############################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 체크 결과 카운터
PASS=0
WARN=0
FAIL=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Zabbix 설치 전 시스템 요구사항 체크${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASS++))
}

check_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((WARN++))
}

check_fail() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAIL++))
}

print_header

# 1. OS 체크
echo -e "${BLUE}[1] 운영체제 체크${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    check_pass "OS: $NAME $VERSION"
else
    check_warn "OS 정보를 확인할 수 없습니다."
fi
echo ""

# 2. Root 권한 체크
echo -e "${BLUE}[2] 권한 체크${NC}"
if [ "$EUID" -eq 0 ]; then
    check_pass "Root 권한으로 실행 중"
else
    check_warn "Root 권한이 아닙니다. 설치 시 'sudo'가 필요합니다."
fi
echo ""

# 3. 메모리 체크
echo -e "${BLUE}[3] 시스템 리소스 체크${NC}"
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_MEM -ge 2048 ]; then
    check_pass "메모리: ${TOTAL_MEM}MB (권장: 2GB 이상)"
elif [ $TOTAL_MEM -ge 1024 ]; then
    check_warn "메모리: ${TOTAL_MEM}MB (권장: 2GB 이상, 최소: 1GB)"
else
    check_fail "메모리: ${TOTAL_MEM}MB (부족! 최소 1GB 필요)"
fi

# 4. 디스크 공간 체크
DISK_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $DISK_SPACE -ge 20 ]; then
    check_pass "디스크 여유 공간: ${DISK_SPACE}GB (권장: 20GB 이상)"
elif [ $DISK_SPACE -ge 10 ]; then
    check_warn "디스크 여유 공간: ${DISK_SPACE}GB (권장: 20GB 이상)"
else
    check_fail "디스크 여유 공간: ${DISK_SPACE}GB (부족! 최소 10GB 필요)"
fi
echo ""

# 5. 포트 사용 체크
echo -e "${BLUE}[4] 포트 사용 체크${NC}"
PORTS=(80 443 8847 10847)
for PORT in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        check_warn "포트 $PORT 이미 사용 중"
    else
        check_pass "포트 $PORT 사용 가능"
    fi
done
echo ""

# 6. Docker 설치 체크
echo -e "${BLUE}[5] Docker 체크${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    check_pass "Docker 설치됨 (버전: $DOCKER_VERSION)"
    
    # Docker 서비스 상태 체크
    if systemctl is-active --quiet docker; then
        check_pass "Docker 서비스 실행 중"
    else
        check_warn "Docker 서비스가 실행 중이 아닙니다."
    fi
else
    check_warn "Docker 미설치 (설치 스크립트가 자동으로 설치합니다)"
fi
echo ""

# 7. Docker Compose 체크
echo -e "${BLUE}[6] Docker Compose 체크${NC}"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
    check_pass "Docker Compose 설치됨 (버전: $COMPOSE_VERSION)"
else
    check_warn "Docker Compose 미설치 (설치 스크립트가 자동으로 설치합니다)"
fi
echo ""

# 8. 네트워크 연결 체크
echo -e "${BLUE}[7] 네트워크 연결 체크${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    check_pass "인터넷 연결 정상"
else
    check_fail "인터넷 연결 불가 (설치에 인터넷 연결이 필요합니다)"
fi

if ping -c 1 google.com &> /dev/null; then
    check_pass "DNS 해석 정상"
else
    check_warn "DNS 해석 실패 (네트워크 설정을 확인하세요)"
fi
echo ""

# 9. 방화벽 체크
echo -e "${BLUE}[8] 방화벽 체크${NC}"
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        check_warn "UFW 방화벽 활성화됨 (필요한 포트를 열어야 합니다)"
        echo "      필요한 포트: 80, 443, 8847, 10847"
    else
        check_pass "UFW 방화벽 비활성화됨"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        check_warn "firewalld 활성화됨 (필요한 포트를 열어야 합니다)"
    else
        check_pass "firewalld 비활성화됨"
    fi
else
    check_pass "방화벽 미설치"
fi
echo ""

# 10. 필수 패키지 체크
echo -e "${BLUE}[9] 필수 패키지 체크${NC}"
REQUIRED_PACKAGES=("curl" "wget" "git")
for PKG in "${REQUIRED_PACKAGES[@]}"; do
    if command -v $PKG &> /dev/null; then
        check_pass "$PKG 설치됨"
    else
        check_warn "$PKG 미설치 (권장)"
    fi
done
echo ""

# 결과 요약
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  체크 결과 요약${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}통과: $PASS${NC}"
echo -e "${YELLOW}경고: $WARN${NC}"
echo -e "${RED}실패: $FAIL${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}⚠️  실패 항목이 있습니다. 문제를 해결한 후 설치를 진행하세요.${NC}"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠️  경고 항목이 있지만 설치를 진행할 수 있습니다.${NC}"
    echo -e "${YELLOW}   설치 스크립트가 대부분의 문제를 자동으로 해결합니다.${NC}"
else
    echo -e "${GREEN}✓ 모든 체크를 통과했습니다! 설치를 진행할 수 있습니다.${NC}"
fi
echo ""
echo -e "설치를 시작하려면: ${GREEN}sudo ./install.sh${NC}"
echo ""

