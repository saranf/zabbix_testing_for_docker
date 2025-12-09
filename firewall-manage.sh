#!/bin/bash

#############################################
# 방화벽 관리 스크립트
#############################################

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  방화벽 관리 스크립트${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "사용법: $0 [명령어]"
    echo ""
    echo "명령어:"
    echo "  status    - 방화벽 상태 확인"
    echo "  rules     - 현재 방화벽 규칙 확인"
    echo "  logs      - 방화벽 로그 확인"
    echo "  restart   - 방화벽 재시작"
    echo "  stop      - 방화벽 중지"
    echo "  start     - 방화벽 시작"
    echo "  test      - 포트 테스트"
    echo ""
}

check_firewall() {
    if ! docker-compose ps | grep -q "zabbix-firewall"; then
        echo -e "${RED}방화벽 컨테이너가 실행 중이 아닙니다.${NC}"
        return 1
    fi
    return 0
}

case "$1" in
    status)
        echo -e "${BLUE}[방화벽 상태]${NC}"
        docker-compose ps zabbix-firewall
        echo ""
        if check_firewall; then
            echo -e "${GREEN}방화벽이 실행 중입니다.${NC}"
        fi
        ;;
    
    rules)
        echo -e "${BLUE}[현재 방화벽 규칙]${NC}"
        if check_firewall; then
            docker-compose exec zabbix-firewall iptables -L -n -v --line-numbers
        fi
        ;;
    
    logs)
        echo -e "${BLUE}[방화벽 로그]${NC}"
        docker-compose logs -f zabbix-firewall
        ;;
    
    restart)
        echo -e "${YELLOW}방화벽 재시작 중...${NC}"
        docker-compose restart zabbix-firewall
        sleep 3
        echo -e "${GREEN}방화벽이 재시작되었습니다.${NC}"
        docker-compose logs --tail=20 zabbix-firewall
        ;;
    
    stop)
        echo -e "${YELLOW}방화벽 중지 중...${NC}"
        docker-compose stop zabbix-firewall
        echo -e "${RED}⚠️  방화벽이 중지되었습니다. 서버가 보호되지 않습니다!${NC}"
        ;;
    
    start)
        echo -e "${GREEN}방화벽 시작 중...${NC}"
        docker-compose up -d zabbix-firewall
        sleep 3
        echo -e "${GREEN}방화벽이 시작되었습니다.${NC}"
        docker-compose logs --tail=20 zabbix-firewall
        ;;
    
    test)
        echo -e "${BLUE}[포트 테스트]${NC}"
        echo ""
        echo "외부에서 접근 가능한 포트:"
        
        PORTS=(22 80 443 10847)
        for PORT in "${PORTS[@]}"; do
            if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
                echo -e "  ${GREEN}✓${NC} 포트 $PORT - LISTENING"
            else
                echo -e "  ${RED}✗${NC} 포트 $PORT - CLOSED"
            fi
        done
        
        echo ""
        echo "방화벽 규칙 요약:"
        if check_firewall; then
            docker-compose exec zabbix-firewall iptables -L INPUT -n | grep -E "ACCEPT|DROP" | head -10
        fi
        ;;
    
    *)
        show_help
        ;;
esac

