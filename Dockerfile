FROM	alpine:3.12.3

LABEL	org.label-schema.description="Useful network related tools"
LABEL	org.label-schema.vendor=travelping.com
LABEL	org.label-schema.copyright=travelping.com
LABEL	org.label-schema.version=1.10.2

RUN		apk add --no-cache --update \
		bash \
		conntrack-tools \
		coreutils \
		curl \
		drill \
		iperf3 \
		iproute2 \
		iptables \
		iputils \
		ip6tables \
		keepalived \
		net-tools \
		nftables \
		socat \
		ethtool \
		mtr \
		tcpdump \
		busybox-extras
