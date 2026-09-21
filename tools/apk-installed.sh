#!/bin/sh
# Usage: tools/apk-installed.sh [--platform <platform>] <cri> <image> [<setup-command>]
#
# Prints the packages installed in <image>, one `pkg=version-release` line per
# package, sorted. With a <setup-command> that command runs in the container
# first, so the snapshot covers whatever it installed.
#
# --platform picks the arch of a multi-arch image, e.g. linux/amd64. Note that
# this runs the image rather than unpacking it, so a foreign arch needs
# emulation (qemu-user-static / the podman machine's binfmt setup) and will be
# slow; without it the run fails with an exec format error.
#
# This is the one place that defines what such a line looks like. Both callers
# depend on that: tools/gen-apk-lock.sh writes these lines into apks.lock, and
# `mise run image:packages` prints them for an already-built image so the two
# can be diffed. A format that drifted between the two would make that diff
# lie rather than fail.
#
# The two uses are otherwise opposites. With a setup command this resolves --
# a fresh base image, upgraded, packages installed, versions as the branch
# carries them today. Without one it reads back a frozen db: what some image
# actually ships, no upgrade, no branch lookup.
set -eu

PLATFORM=
while [ "$#" -gt 0 ]; do
    case $1 in
        --platform)   [ "$#" -ge 2 ] || { echo "--platform needs a value" >&2; exit 1; }
                      PLATFORM=$2; shift 2 ;;
        --platform=*) PLATFORM=${1#*=}; shift ;;
        --)           shift; break ;;
        -*)           echo "unknown option: $1" >&2; exit 1 ;;
        *)            break ;;
    esac
done

CRI=$1; shift
IMAGE=$1; shift
SETUP=${1:-}

if [ -n "$PLATFORM" ]; then
    set -- --platform "$PLATFORM"
else
    set --
fi

command -v jq >/dev/null || { echo "jq is required on the host" >&2; exit 1; }
command -v "$CRI" >/dev/null || { echo "$CRI not found on the host" >&2; exit 1; }

# --entrypoint: the image may well declare one (the nettools image starts a
# shell), and we want our own command, not its arguments.
#
# The setup command is forced onto stderr: only the JSON below may reach
# stdout, and `apk add` is chatty.
json=$("$CRI" run --rm "$@" --entrypoint sh "$IMAGE" -ec "
    command -v apk >/dev/null || {
        echo 'no apk in this image; it is not alpine-based' >&2
        exit 1
    }
    # The ':' keeps this a valid compound list when there is no setup command:
    # '{ ; }' is a syntax error, '{ :\n\n }' is not.
    {
        :
        $SETUP
    } 1>&2
    pkgs=\$(awk '/^P:/{print substr(\$0,3)}' /lib/apk/db/installed | tr '\n' ' ')
    # Versions come from the installed db; an empty repositories file keeps apk
    # from opening the remote indexes that --no-cache may not have left behind
    # (which would otherwise warn 'opening from cache ...: No such file').
    apk info --repositories-file /dev/null --format=json \$pkgs
")

if [ -z "$json" ]; then
    echo "container produced no JSON output" >&2
    exit 1
fi

out=$(printf '%s\n' "$json" | jq -r '.[] | "\(.name)=\(.version)"' | sort -u)

if [ -z "$out" ]; then
    echo "jq produced no entries; raw container output was:" >&2
    printf '%s\n' "$json" >&2
    exit 1
fi

printf '%s\n' "$out"
