FROM alpine:3.15 as builder

WORKDIR /workspace

RUN	apk add --no-cache --update \
		linux-headers \
		alpine-sdk \
		coreutils \
		bash \
		git \
		flex \
		bison

RUN git clone git://github.com/netsniff-ng/netsniff-ng.git
RUN cd netsniff-ng

WORKDIR /workspace/netsniff-ng
RUN git checkout v0.6.7

RUN ./configure && make && mkdir /usr/local/sbin && make install

FROM	alpine:3.15

LABEL	org.label-schema.description="Useful network related tools"
LABEL	org.label-schema.vendor=travelping.com
LABEL	org.label-schema.copyright=travelping.com
LABEL	org.label-schema.version=1.10.1

COPY --from=builder /usr/local/sbin/bpfc /usr/local/sbin/bpfc
COPY --from=builder /usr/local/sbin/netsniff-ng /usr/local/sbin/netsniff-ng
COPY --from=builder /usr/local/sbin/trafgen /usr/local/sbin/trafgen

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
