#!/bin/bash

#############################################
# Docker 방화벽 규칙 설정
# iptables 기반 보안 설정
#############################################

# 환경 변수에서 포트 읽기 (기본값 설정)
SSH_PORT=${SSH_PORT:-22}
HTTP_PORT=${HTTP_PORT:-80}
HTTPS_PORT=${HTTPS_PORT:-443}
ZABBIX_SERVER_PORT=${ZABBIX_SERVER_PORT:-10847}

echo "[FIREWALL] 방화벽 규칙 적용 중..."
echo "[FIREWALL] 설정된 포트:"
echo "[FIREWALL]   SSH: $SSH_PORT"
echo "[FIREWALL]   HTTP: $HTTP_PORT"
echo "[FIREWALL]   HTTPS: $HTTPS_PORT"
echo "[FIREWALL]   Zabbix Server: $ZABBIX_SERVER_PORT"

# 기본 정책: 모든 INPUT 차단, OUTPUT 허용
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# IPv6도 동일하게 설정
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# 기존 규칙 초기화
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

ip6tables -F
ip6tables -X

echo "[FIREWALL] 기본 정책 설정 완료"

# Loopback 인터페이스 허용
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

echo "[FIREWALL] Loopback 허용"

# 이미 연결된 세션 허용
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

echo "[FIREWALL] 기존 연결 허용"

# ICMP (ping) 제한적 허용 - Rate Limiting
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
ip6tables -A INPUT -p ipv6-icmp -m limit --limit 1/s --limit-burst 3 -j ACCEPT
ip6tables -A INPUT -p ipv6-icmp -j DROP

echo "[FIREWALL] ICMP Rate Limiting 설정"

# SSH - Rate Limiting으로 브루트포스 방지
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT

echo "[FIREWALL] SSH 포트 $SSH_PORT 허용 (브루트포스 방지)"

# HTTP - Rate Limiting
iptables -A INPUT -p tcp --dport $HTTP_PORT -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --dport $HTTP_PORT -m state --state NEW -j DROP

echo "[FIREWALL] HTTP 포트 $HTTP_PORT 허용 (Rate Limiting)"

# HTTPS - Rate Limiting
iptables -A INPUT -p tcp --dport $HTTPS_PORT -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --dport $HTTPS_PORT -m state --state NEW -j DROP

echo "[FIREWALL] HTTPS 포트 $HTTPS_PORT 허용 (Rate Limiting)"

# Zabbix Server - Zabbix Agent 통신용
iptables -A INPUT -p tcp --dport $ZABBIX_SERVER_PORT -j ACCEPT

echo "[FIREWALL] Zabbix Server 포트 $ZABBIX_SERVER_PORT 허용"

# SYN Flood 공격 방지
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

echo "[FIREWALL] SYN Flood 방지 설정"

# Port Scanning 방지
iptables -N port-scanning
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A port-scanning -j DROP

echo "[FIREWALL] Port Scanning 방지 설정"

# Invalid 패킷 차단
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP

echo "[FIREWALL] Invalid 패킷 차단"

# Fragmented 패킷 차단
iptables -A INPUT -f -j DROP

echo "[FIREWALL] Fragmented 패킷 차단"

# XMAS 패킷 차단
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

echo "[FIREWALL] XMAS 패킷 차단"

# NULL 패킷 차단
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

echo "[FIREWALL] NULL 패킷 차단"

# 로그 설정 (차단된 패킷 로깅 - 제한적)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-denied: " --log-level 7
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables-FORWARD-denied: " --log-level 7

echo "[FIREWALL] 로깅 설정 완료"

# Docker 네트워크 허용 (내부 통신)
# Docker가 자동으로 설정하는 규칙과 충돌하지 않도록 주의
iptables -A INPUT -i docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -j ACCEPT

echo "[FIREWALL] Docker 네트워크 허용"

# 규칙 저장
if [ -d /etc/iptables ]; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true
fi

echo "[FIREWALL] =========================================="
echo "[FIREWALL] 방화벽 규칙 적용 완료!"
echo "[FIREWALL] =========================================="
echo "[FIREWALL] 허용된 포트:"
echo "[FIREWALL]   - $SSH_PORT (SSH) - 브루트포스 방지"
echo "[FIREWALL]   - $HTTP_PORT (HTTP) - Rate Limiting"
echo "[FIREWALL]   - $HTTPS_PORT (HTTPS) - Rate Limiting"
echo "[FIREWALL]   - $ZABBIX_SERVER_PORT (Zabbix Server)"
echo "[FIREWALL] =========================================="

# 현재 규칙 출력
echo ""
echo "[FIREWALL] 현재 적용된 규칙:"
iptables -L -n -v --line-numbers

