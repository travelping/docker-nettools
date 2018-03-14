FROM	alpine:3.7
RUN apk add --update \
	bash \
	curl \
	drill \
	iperf3 \
	iproute2 \
	net-tools \
	socat \
	tcpdump
