#!/bin/bash

#############################################
# 보안 설정 테스트 스크립트
#############################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN=${1:-zabbix.rmstudio.co.kr}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  보안 설정 테스트${NC}"
echo -e "${BLUE}  도메인: $DOMAIN${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. SSL/TLS 테스트
echo -e "${BLUE}[1] SSL/TLS 프로토콜 테스트${NC}"
if command -v openssl &> /dev/null; then
    echo "TLS 1.2 테스트:"
    timeout 5 openssl s_client -connect $DOMAIN:443 -tls1_2 < /dev/null 2>&1 | grep "Protocol"
    
    echo "TLS 1.3 테스트:"
    timeout 5 openssl s_client -connect $DOMAIN:443 -tls1_3 < /dev/null 2>&1 | grep "Protocol"
    
    echo "TLS 1.1 테스트 (차단되어야 함):"
    timeout 5 openssl s_client -connect $DOMAIN:443 -tls1_1 < /dev/null 2>&1 | grep -E "Protocol|alert"
else
    echo -e "${YELLOW}openssl이 설치되어 있지 않습니다.${NC}"
fi
echo ""

# 2. 보안 헤더 테스트
echo -e "${BLUE}[2] 보안 헤더 테스트${NC}"
if command -v curl &> /dev/null; then
    HEADERS=$(curl -s -I https://$DOMAIN 2>/dev/null)
    
    check_header() {
        HEADER=$1
        if echo "$HEADERS" | grep -qi "$HEADER"; then
            echo -e "${GREEN}✓${NC} $HEADER 설정됨"
            echo "$HEADERS" | grep -i "$HEADER"
        else
            echo -e "${RED}✗${NC} $HEADER 설정되지 않음"
        fi
    }
    
    check_header "Strict-Transport-Security"
    check_header "X-Frame-Options"
    check_header "X-Content-Type-Options"
    check_header "X-XSS-Protection"
    check_header "Content-Security-Policy"
    check_header "Referrer-Policy"
    check_header "Permissions-Policy"
    
    # 서버 정보 숨김 확인
    if echo "$HEADERS" | grep -qi "Server:"; then
        SERVER_INFO=$(echo "$HEADERS" | grep -i "Server:")
        if echo "$SERVER_INFO" | grep -qi "nginx/"; then
            echo -e "${RED}✗${NC} 서버 버전 정보 노출: $SERVER_INFO"
        else
            echo -e "${GREEN}✓${NC} 서버 정보 숨김: $SERVER_INFO"
        fi
    else
        echo -e "${GREEN}✓${NC} Server 헤더 완전 제거됨"
    fi
else
    echo -e "${YELLOW}curl이 설치되어 있지 않습니다.${NC}"
fi
echo ""

# 3. Rate Limiting 테스트
echo -e "${BLUE}[3] Rate Limiting 테스트${NC}"
echo "연속 20개 요청 전송 중..."
SUCCESS=0
FAILED=0
for i in {1..20}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN 2>/dev/null)
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        ((SUCCESS++))
    elif [ "$STATUS" == "429" ] || [ "$STATUS" == "503" ]; then
        ((FAILED++))
    fi
done
echo -e "성공: ${GREEN}$SUCCESS${NC}, Rate Limited: ${YELLOW}$FAILED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Rate Limiting 작동 중"
else
    echo -e "${YELLOW}!${NC} Rate Limiting 확인 필요 (더 많은 요청 필요)"
fi
echo ""

# 4. HTTP to HTTPS 리다이렉트 테스트
echo -e "${BLUE}[4] HTTP to HTTPS 리다이렉트 테스트${NC}"
HTTP_RESPONSE=$(curl -s -I http://$DOMAIN 2>/dev/null | head -n 1)
if echo "$HTTP_RESPONSE" | grep -q "301\|302"; then
    echo -e "${GREEN}✓${NC} HTTP가 HTTPS로 리다이렉트됨"
    curl -s -I http://$DOMAIN 2>/dev/null | grep -i "location"
else
    echo -e "${RED}✗${NC} HTTP 리다이렉트 설정되지 않음"
fi
echo ""

# 5. 숨겨진 파일 접근 테스트
echo -e "${BLUE}[5] 숨겨진 파일 접근 차단 테스트${NC}"
HIDDEN_FILES=(".env" ".git/config" "config.php.bak" "backup.sql")
for FILE in "${HIDDEN_FILES[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/$FILE 2>/dev/null)
    if [ "$STATUS" == "403" ] || [ "$STATUS" == "404" ]; then
        echo -e "${GREEN}✓${NC} $FILE 접근 차단됨 (HTTP $STATUS)"
    else
        echo -e "${RED}✗${NC} $FILE 접근 가능 (HTTP $STATUS)"
    fi
done
echo ""

# 6. Docker 컨테이너 상태 확인
echo -e "${BLUE}[6] Docker 컨테이너 상태${NC}"
if command -v docker-compose &> /dev/null; then
    docker-compose ps
else
    echo -e "${YELLOW}docker-compose가 설치되어 있지 않습니다.${NC}"
fi
echo ""

# 7. 포트 노출 확인
echo -e "${BLUE}[7] 포트 노출 확인${NC}"
echo "외부 노출 포트:"
docker-compose ps 2>/dev/null | grep -E "80|443|10847" || echo "docker-compose를 사용할 수 없습니다."
echo ""

# 결과 요약
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  테스트 완료${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "추가 보안 테스트:"
echo "  - SSL Labs: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo "  - Security Headers: https://securityheaders.com/?q=$DOMAIN"
echo "  - Mozilla Observatory: https://observatory.mozilla.org/analyze/$DOMAIN"
echo ""

