#!/usr/bin/env bash
set -euo pipefail

PLATFORM=ios
if [[ "${1:-}" == "--maccatalyst" ]]; then
  PLATFORM=maccatalyst
  shift
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(mkdir -p "${1:-$SRC/dist/cloudflared-JESSI}" && cd "${1:-$SRC/dist/cloudflared-JESSI}" && pwd)"
VERSION="$(git -C "$SRC" describe --tags --always 2>/dev/null || echo DEV)"

if [[ "$PLATFORM" == "maccatalyst" ]]; then
  SDK="$(xcrun --sdk macosx --show-sdk-path)"
  CLANG="$(xcrun --sdk macosx -f clang)"
  FLAGS="-isysroot $SDK -target arm64-apple-ios14.0-macabi -iframework $SDK/System/iOSSupport/System/Library/Frameworks"
  NAME="libcloudflared-maccatalyst.dylib"
else
  SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
  CLANG="$(xcrun --sdk iphoneos -f clang)"
  FLAGS="-isysroot $SDK -arch arm64 -miphoneos-version-min=14.0"
  NAME="libcloudflared.dylib"
fi

(
  cd "$SRC"
  GOOS=ios GOARCH=arm64 CGO_ENABLED=1 CC="$CLANG $FLAGS" CGO_CFLAGS="$FLAGS" CGO_LDFLAGS="$FLAGS" \
    go build -trimpath -buildmode=c-archive -ldflags "-s -w -X main.Version=$VERSION" \
    -o "$OUT/libcloudflared.a" ./cmd/cloudflared
)

$CLANG $FLAGS -dynamiclib -o "$OUT/$NAME" \
  -Wl,-force_load,"$OUT/libcloudflared.a" \
  -install_name @rpath/libcloudflared.dylib \
  -framework CoreFoundation -framework Security -lresolv

rm -f "$OUT/libcloudflared.a"
codesign --force --sign - "$OUT/$NAME"
codesign --verify "$OUT/$NAME"
echo "Built $OUT/$NAME ($VERSION)"
