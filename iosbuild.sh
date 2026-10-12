#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(mkdir -p "${1:-$SRC/dist/cloudflared-JESSI}" && cd "${1:-$SRC/dist/cloudflared-JESSI}" && pwd)"
VERSION="$(git -C "$SRC" describe --tags --always 2>/dev/null || echo DEV)"

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang)"
FLAGS="-isysroot $SDK -arch arm64 -miphoneos-version-min=14.0"

(
  cd "$SRC"
  GOOS=ios GOARCH=arm64 CGO_ENABLED=1 CC="$CLANG $FLAGS" CGO_CFLAGS="$FLAGS" CGO_LDFLAGS="$FLAGS" \
    go build -trimpath -buildmode=c-archive -ldflags "-s -w -X main.Version=$VERSION" \
    -o "$OUT/libcloudflared.a" ./cmd/cloudflared
)

$CLANG $FLAGS -dynamiclib -o "$OUT/libcloudflared.dylib" \
  -Wl,-force_load,"$OUT/libcloudflared.a" \
  -install_name @rpath/libcloudflared.dylib \
  -framework CoreFoundation -framework Security -lresolv

rm -f "$OUT/libcloudflared.a"
codesign --force --sign - "$OUT/libcloudflared.dylib"
codesign --verify "$OUT/libcloudflared.dylib"
echo "Built $OUT/libcloudflared.dylib ($VERSION)"
