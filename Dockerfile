FROM	alpine:3.7
RUN apk add --update \
	bash \
	conntrack-tools \
	coreutils \
	curl \
	drill \
	iperf3 \
	iproute2 \
	iptables \
	ip6tables \
	keepalived \
	net-tools \
	nftables \
	socat \
	ethtool \
	tcpdump
