FROM alpine:latest

# iptables 및 필수 패키지 설치
RUN apk add --no-cache \
    iptables \
    ip6tables \
    bash \
    curl

# 방화벽 스크립트 복사
COPY firewall-rules.sh /usr/local/bin/firewall-rules.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 실행 권한 부여
RUN chmod +x /usr/local/bin/firewall-rules.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Entrypoint 설정
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

