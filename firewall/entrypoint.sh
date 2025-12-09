#!/bin/bash

echo "[FIREWALL] 방화벽 컨테이너 시작..."

# 방화벽 규칙 적용
/usr/local/bin/firewall-rules.sh

# 규칙 적용 확인
if [ $? -eq 0 ]; then
    echo "[FIREWALL] 방화벽 규칙이 성공적으로 적용되었습니다."
else
    echo "[FIREWALL] 방화벽 규칙 적용 실패!"
    exit 1
fi

# 주기적으로 규칙 확인 및 재적용 (1시간마다)
while true; do
    sleep 3600
    echo "[FIREWALL] 방화벽 규칙 재확인 중..."
    
    # 규칙이 여전히 적용되어 있는지 확인
    RULE_COUNT=$(iptables -L INPUT -n | wc -l)
    if [ "$RULE_COUNT" -lt 5 ]; then
        echo "[FIREWALL] 규칙이 손실되었습니다. 재적용 중..."
        /usr/local/bin/firewall-rules.sh
    else
        echo "[FIREWALL] 방화벽 규칙 정상 작동 중 (규칙 수: $RULE_COUNT)"
    fi
done

