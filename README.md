# Nettools

A simple, small, Alpine-based container image with some handy networking tools
installed.

## Tools built from source

Pinned to an upstream tag in the `Dockerfile`, compiled in the builder stage:

- `netsniff-ng`, `trafgen`, `bpfc` -- capture, replay and BPF compilation
- `gtping` -- GTP echo probe

## Packages from Alpine

Edit [`apks.list`](apks.list) to change this set; the list below is generated
from it.

<!-- packages -->

- `bash` -- full shell, not the busybox ash applet
- `busybox-extras` -- telnet/ftpget/httpd: applets the base busybox omits
- `conntrack-tools` -- conntrack/nfct: read and flush the kernel conntrack table
- `coreutils` -- GNU od, stat, timeout and friends, not the busybox applets
- `curl` -- HTTP(S) client
- `drill` -- DNS lookups, including DNSSEC chases
- `ethtool` -- NIC link state, driver info, offload and ring settings
- `eudev` -- udevd/udevadm: interface naming and device rules
- `iperf3` -- TCP/UDP throughput measurement
- `iproute2` -- ip/ss/tc: addresses, routes, sockets, qdiscs
- `iptables` -- iptables/ip6tables/ebtables/arptables, nft-backed
- `iputils` -- ping/arping/tracepath: reachability and path checks
- `keepalived` -- VRRP for failover experiments
- `lz4` -- compression and decompression of captures and blobs
- `mtr` -- traceroute and ping in one continuous view
- `net-tools` -- ifconfig/netstat/route: for runbooks that still use them
- `nftables` -- nft: the current packet filter
- `openssl` -- TLS client, certificate and cipher inspection
- `socat` -- relays between arbitrary sockets, pipes and ttys
- `tcpdump` -- packet capture
- `tshark` -- tshark/dumpcap/mergecap: the Wireshark CLI tools
- `zstd` -- compression and decompression of captures and blobs

<!-- packagesstop -->

## Building

```
mise run image:build [image] [cri] [platforms]
```

Refuses to build if `apks.lock` does not cover `apks.list`, or if the
`Dockerfile`'s Alpine version has drifted from `.mise/config.toml`.

## Maintenance

| Command                                  | Effect                                                                       |
| ---                                      | ---                                                                          |
| `mise run image:apk-lock`                | resolve `apks.list` on a clean `alpine:$ALPINE_VERSION`, rewrite `apks.lock` |
| `mise run image:packages`                | list what a built image actually ships, in `apks.lock` format                |
| `mise run docs:packages`                 | re-render the package list above                                             |
| `mise run image:report-trivy` / `-grype` | scan a locally built image                                                   |
| `mise run ci:update-actions`             | repin GitHub Actions                                                         |
| `mise run tools:lock`                    | update `.mise/mise.lock`                                                     |

**Adding or dropping a package**:

1. edit [`apks.list`](apks.list) -- one `name  # what it is for` line
2. `mise run image:apk-lock` -- rewrites `apks.lock` with the new resolved set
3. `mise run docs:packages` -- re-renders the list above from the comments
4. commit all three files together

`apks.lock` holds the full resolved set at exact versions and is never edited
by hand; upgrades come from a regeneration, not from an `apk upgrade` in the
`Dockerfile`. Use the name of a real package, not of a virtual one: `ip6tables`
and `udev` are `provides` of `iptables` and `eudev`, never appear in the lock,
and make `image:build` fail its list-covered-by-lock check.

**Verifying a built image**: `image:packages` reads the installed db out of an
image -- local or from a registry -- and prints it in the lock's format, so

```
mise run image:packages registry.cennso.com/cennso/nettools:v1.19.0 | \
    diff <(grep -v '^#' apks.lock) -
```

answers whether what shipped is what the lock says. Both it and `image:apk-lock`
go through `tools/apk-installed.sh`; add `--platform linux/amd64` for a
multi-arch image, which needs emulation to run on another arch.

**Alpine base**: bump `ALPINE_VERSION` in `.mise/config.toml` and the
`Dockerfile` `ARG` together, then regenerate the lock.

**Distrusted root CAs**: the image build filters
`/etc/ssl/certs/ca-certificates.crt` against
[`tools/ca-distrust.sha256`](tools/ca-distrust.sha256), one SHA-256 fingerprint
of the DER certificate per line. When `ca-certificates-bundle` moves in the
lock, check whether upstream now drops a listed root itself; the entry stays
listed regardless, so a reverted bundle is filtered the same way.

**Source-built tools**: bump the `--branch` tags in the `Dockerfile`. That
stage is not locked -- nothing from it reaches the runtime image except those
binaries.
