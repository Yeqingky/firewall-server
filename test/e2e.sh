#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d)
pid=
cleanup() {
    [ -z "$pid" ] || kill "$pid" 2>/dev/null || true
    [ -z "$pid" ] || wait "$pid" 2>/dev/null || true
    rm -r -- "$TEST_DIR"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$TEST_DIR/path"
ln -s "$(command -v nft)" "$TEST_DIR/path/nft"
go build -C "$ROOT" -o "$TEST_DIR/edge-firewall-server" ./cmd/edge-firewall-server
PATH="$TEST_DIR/path" "$TEST_DIR/edge-firewall-server" -addr 127.0.0.1:15843 >"$TEST_DIR/server.log" 2>&1 &
pid=$!
for _ in $(seq 1 30); do
    if curl -fsS --connect-timeout 1 --max-time 2 http://127.0.0.1:15843/name >"$TEST_DIR/name.json" 2>/dev/null; then
        break
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
        cat "$TEST_DIR/server.log" >&2
        exit 1
    fi
    sleep 1
done
if ! grep -q '"name":"nftables"' "$TEST_DIR/name.json"; then
    cat "$TEST_DIR/server.log" >&2
    echo 'real nftables backend was not started' >&2
    exit 1
fi

curl -fsS --max-time 5 'http://127.0.0.1:15843/dropSourceIP?ip=192.0.2.123&timeoutSeconds=60' >/dev/null
nft list table ip edge_dft_v4 | grep -q '192.0.2.123'
curl -fsS --max-time 5 'http://127.0.0.1:15843/removeSourceIP?ip=192.0.2.123' >/dev/null
if nft list table ip edge_dft_v4 | grep -q '192.0.2.123'; then
    echo 'source IP is still blocked after removal' >&2
    exit 1
fi
status=$(curl -sS --max-time 5 -o /dev/null -w '%{http_code}' 'http://127.0.0.1:15843/dropSourceIP?ip=invalid')
[ "$status" = 400 ]
