ARG ALPINE_VERSION=3.24.3

FROM alpine:${ALPINE_VERSION} AS builder

WORKDIR /workspace

# Deliberately unpinned: nothing from this stage is copied into the runtime
# image except the binaries built below, so these packages never reach a
# scanner or a running container. Only apks.lock -- the runtime set -- is
# worth the regeneration cycle.
RUN apk upgrade --no-cache && \
    apk add --no-cache \
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

FROM alpine:${ALPINE_VERSION} AS runtime

LABEL org.label-schema.description="Useful network related tools"
LABEL org.label-schema.vendor=travelping.com
LABEL org.label-schema.copyright=travelping.com
LABEL org.label-schema.version=1.19.0

COPY apks.lock /tmp/apks.lock

# apks.lock pins every package to an exact version, including the base set that
# alpine:${ALPINE_VERSION} ships. An `apk upgrade` here would be undone by those
# pins anyway -- upgrades enter through `mise run image:apk-lock`, not through
# the image build. The grep drops the generated header comments.
RUN grep -v '^#' /tmp/apks.lock | xargs apk add --no-cache && rm /tmp/apks.lock

COPY --from=builder /usr/local/sbin/bpfc /usr/local/sbin/bpfc
COPY --from=builder /usr/local/sbin/netsniff-ng /usr/local/sbin/netsniff-ng
COPY --from=builder /usr/local/sbin/trafgen /usr/local/sbin/trafgen
COPY --from=builder /usr/local/bin/gtping /usr/local/bin/gtping
