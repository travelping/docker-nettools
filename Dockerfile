FROM alpine:3.24.1 AS builder

WORKDIR /workspace

RUN apk add --no-cache --update \
        linux-headers \
        alpine-sdk \
        coreutils \
        bash \
        git \
        flex \
        bison

RUN git clone --branch v0.6.9 --depth 1 https://github.com/netsniff-ng/netsniff-ng.git

WORKDIR /workspace/netsniff-ng
RUN mkdir /etc/netsniff-ng && cp trafgen_stddef.h /etc/netsniff-ng
RUN ./configure && make && mkdir /usr/local/sbin && make install

WORKDIR /workspace
RUN git clone --branch gtping-0.15 --depth 1 https://github.com/ThomasHabets/gtping.git
WORKDIR /workspace/gtping
RUN ./configure && make && make install

FROM alpine:3.24.1 AS runtime

LABEL org.label-schema.description="Useful network related tools"
LABEL org.label-schema.vendor=travelping.com
LABEL org.label-schema.copyright=travelping.com
LABEL org.label-schema.version=1.19.0

COPY --from=builder /usr/local/sbin/bpfc /usr/local/sbin/bpfc
COPY --from=builder /usr/local/sbin/netsniff-ng /usr/local/sbin/netsniff-ng
COPY --from=builder /usr/local/sbin/trafgen /usr/local/sbin/trafgen
COPY --from=builder /usr/local/bin/gtping /usr/local/bin/gtping

RUN apk add --no-cache --update \
        bash                    \
        busybox-extras          \
        conntrack-tools         \
        coreutils               \
        curl                    \
        drill                   \
        ethtool                 \
        ip6tables               \
        iperf3                  \
        iproute2                \
        iptables                \
        iputils                 \
        keepalived              \
        lz4                     \
        mtr                     \
        net-tools               \
        nftables                \
        openssl                 \
        socat                   \
        tcpdump                 \
        tshark                  \
        udev                    \
        zstd
