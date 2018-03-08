FROM	alpine:3.7
RUN	apk update && apk add iproute2 tcpdump iperf3 net-tools socat
