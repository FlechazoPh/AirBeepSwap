#!/bin/bash
# AirBeepSwap — maintained by Poner7.
# https://github.com/poner7/AirBeepSwap
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/airbeepswap-compatibility.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

cat > "$TEST_DIR/main.swift" <<'SWIFT'
import Foundation

let cases: [(Int, Int, Int, Bool)] = [
    (17, 7, 0, false),
    (18, 0, 0, true),
    (26, 0, 1, true),
    (27, 0, 0, true),
    (27, 0, 1, true), // iPhone 18 Pro Max target
    (27, 1, 0, true),
    (27, 2, 0, true),
    (27, 2, 1, false),
    (27, 3, 0, false),
    (28, 0, 0, false)
]
for (major, minor, patch, expected) in cases {
    let version = OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)
    precondition(SystemCompatibility.isSupported(version: version) == expected,
                 "Unexpected compatibility for \(major).\(minor).\(patch)")
}
print("PASS: \(cases.count) system version checks, including iOS 27.0.1")
SWIFT

xcrun swiftc "$ROOT/airbeepswap/SystemCompatibility.swift" "$TEST_DIR/main.swift" -o "$TEST_DIR/check"
"$TEST_DIR/check"
