FROM	alpine:3.7
RUN apk add --update \
	bash \
	coreutils \
	curl \
	drill \
	iperf3 \
	iproute2 \
	iptables \
	ip6tables \
	keepalived \
	net-tools \
	socat \
	tcpdump
