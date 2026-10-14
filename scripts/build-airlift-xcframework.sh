#!/bin/bash
# AirBeepSwap — maintained by Poner7.
# https://github.com/poner7/AirBeepSwap
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AIRCARD_REPO="${AIRCARD_REPO:-https://github.com/mak5er/AirCard-iOS.git}"
AIRCARD_COMMIT="${AIRCARD_COMMIT:-40640c4d827aeab8d798285b57d24fcf6be070d0}"
BUILD_PARENT="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
BUILD_ROOT="$BUILD_PARENT/airbeepswap-aircard-$AIRCARD_COMMIT"
PATCH_FILE="$ROOT/scripts/airlift-read-file.patch"

# AirCard's build script otherwise defaults to a beta Xcode app that is not
# present on the GitHub runner. setup-xcode has already selected the right one.
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"

for tool in cargo rustup; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool. Install Rust and add its bin directory to PATH." >&2
    exit 1
  fi
done

rm -rf "$BUILD_ROOT"
git clone --quiet --filter=blob:none "$AIRCARD_REPO" "$BUILD_ROOT"
git -C "$BUILD_ROOT" checkout --quiet --detach "$AIRCARD_COMMIT"

# Make the Rust LLVM nm available so verify-airlift.sh can inspect the
# patch-added symbols. The Xcode nm cannot read Rust's compiler_builtins
# objects (LLVM version mismatch).
if command -v rustup >/dev/null 2>&1; then
  rustup component add llvm-tools-preview 2>/dev/null || true
fi

git -C "$BUILD_ROOT" apply --check --3way "$PATCH_FILE"
git -C "$BUILD_ROOT" apply --3way "$PATCH_FILE"

# Build here instead of invoking AirCard's script, which unconditionally
# sources ~/.cargo/env and can exit before building with an isolated Rust
# installation. Honor the caller's PATH, CARGO_HOME and RUSTUP_HOME.
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-18.0}"
export RUSTFLAGS="${RUSTFLAGS:-} --remap-path-prefix=$BUILD_ROOT=/build/aircard"
export CFLAGS="${CFLAGS:-} -ffile-prefix-map=$BUILD_ROOT=/build/aircard"
export TARGET_CFLAGS="${TARGET_CFLAGS:-} -ffile-prefix-map=$BUILD_ROOT=/build/aircard"
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
(
  cd "$BUILD_ROOT/rust-core"
  cargo build --locked --release --target aarch64-apple-ios
  cargo build --locked --release --target aarch64-apple-ios-sim
)
rm -rf "$BUILD_ROOT/AirliftFFI.xcframework"
xcodebuild -create-xcframework \
  -library "$BUILD_ROOT/rust-core/target/aarch64-apple-ios/release/libairlift_ffi.a" \
  -headers "$BUILD_ROOT/rust-core/include" \
  -library "$BUILD_ROOT/rust-core/target/aarch64-apple-ios-sim/release/libairlift_ffi.a" \
  -headers "$BUILD_ROOT/rust-core/include" \
  -output "$BUILD_ROOT/AirliftFFI.xcframework"

rm -rf "$ROOT/Vendor/AirCard/AirliftFFI.xcframework"
cp -R "$BUILD_ROOT/AirliftFFI.xcframework" "$ROOT/Vendor/AirCard/AirliftFFI.xcframework"

python3 - "$ROOT/Vendor/AirCard/AirliftFFI.xcframework" <<'PY'
from pathlib import Path
import sys
for header in Path(sys.argv[1]).glob('*/Headers/airlift.h'):
    header.write_text(header.read_text().rstrip() + '\n')
PY

cd "$ROOT"
{
  find Vendor/AirCard/AirliftFFI.xcframework -type f -print
  printf '%s\n' airbeepswap/Airlift/GrappaHelper.h airbeepswap/Airlift/GrappaHelper.m
} | LC_ALL=C sort | xargs shasum -a 256 > Vendor/AirCard/SHA256SUMS

echo "Built patched AirliftFFI from AirCard-iOS $AIRCARD_COMMIT"
