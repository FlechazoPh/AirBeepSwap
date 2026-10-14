#!/bin/bash
# AirBeepSwap — maintained by Poner7.
# https://github.com/poner7/AirBeepSwap
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/airbeepswap-tunnel.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
cat > "$TEST_DIR/main.swift" <<'SWIFT'
import Foundation

func checksum(_ bytes: [UInt8]) -> UInt16 {
    var sum: UInt32 = 0
    for offset in stride(from: 0, to: bytes.count, by: 2) {
        sum += UInt32(bytes[offset]) << 8
        if offset + 1 < bytes.count { sum += UInt32(bytes[offset + 1]) }
    }
    while sum > 0xffff { sum = (sum & 0xffff) + (sum >> 16) }
    return ~UInt16(sum)
}
func put(_ value: UInt16, at offset: Int, into bytes: inout [UInt8]) {
    bytes[offset] = UInt8(value >> 8)
    bytes[offset + 1] = UInt8(value & 0xff)
}
func packet(_ proto: UInt8, options: Bool = false) -> Data {
    let headerLength = options ? 24 : 20
    let transportLength = (proto == 6 ? 20 : 8) + 7
    var bytes = [UInt8](repeating: 0, count: headerLength + transportLength)
    bytes[0] = 0x40 | UInt8(headerLength / 4)
    put(UInt16(bytes.count), at: 2, into: &bytes)
    bytes[8] = 64
    bytes[9] = proto
    bytes.replaceSubrange(12..<20, with: [10, 7, 1, 1, 10, 7, 0, 1])
    put(54321, at: headerLength, into: &bytes)
    put(49152, at: headerLength + 2, into: &bytes)
    if proto == 6 { bytes[headerLength + 12] = 0x50 }
    else { put(UInt16(transportLength), at: headerLength + 4, into: &bytes) }
    for offset in (bytes.count - 7)..<bytes.count { bytes[offset] = UInt8(offset) }
    let pseudoHeader = Array(bytes[12..<20]) + [0, proto, UInt8(transportLength >> 8), UInt8(transportLength & 0xff)]
    let transportChecksum = checksum(pseudoHeader + Array(bytes[headerLength...]))
    put(transportChecksum, at: headerLength + (proto == 6 ? 16 : 6), into: &bytes)
    let ipChecksum = checksum(Array(bytes[..<headerLength]))
    put(ipChecksum, at: 10, into: &bytes)
    return Data(bytes)
}

for proto: UInt8 in [6, 17] {
    for options in [false, true] {
        let original = packet(proto, options: options)
        let reflected = LoopbackPacket.reflect(original)!
        let bytes = Array(reflected)
        let headerLength = Int(bytes[0] & 0x0f) * 4
        let transportLength = bytes.count - headerLength
        precondition(Array(bytes[12..<20]) == [10, 7, 0, 1, 10, 7, 1, 1])
        precondition(checksum(Array(bytes[..<headerLength])) == 0)
        let pseudoHeader = Array(bytes[12..<20]) + [0, proto, UInt8(transportLength >> 8), UInt8(transportLength & 0xff)]
        precondition(checksum(pseudoHeader + Array(bytes[headerLength...])) == 0)
        precondition(LoopbackPacket.reflect(reflected) == original)
    }
}
let valid = packet(6)
precondition(LoopbackPacket.reflect(Data(valid.prefix(19))) == nil)
var malformed = valid; malformed[0] = 0x44
precondition(LoopbackPacket.reflect(malformed) == nil)
malformed = valid; malformed[0] = 0x65
precondition(LoopbackPacket.reflect(malformed) == nil)
malformed = valid; malformed[2] = 0xff
precondition(LoopbackPacket.reflect(malformed) == nil)
malformed = valid; malformed[12] = 192
precondition(LoopbackPacket.reflect(malformed) == nil)
malformed = valid; malformed[16] = 224
precondition(LoopbackPacket.reflect(malformed) == nil)
print("PASS: IPv4 TCP/UDP reflection, options, checksums and invalid/unrelated packet rejection")
SWIFT
xcrun swiftc "$ROOT/AirBeepTunnel/LoopbackPacket.swift" "$TEST_DIR/main.swift" -o "$TEST_DIR/check"
"$TEST_DIR/check"
