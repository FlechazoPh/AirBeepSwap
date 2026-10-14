// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import Foundation

/// Address reflection follows LocalDevVPN / StosVPN. Swapping the two IPv4
/// addresses leaves the IP and TCP/UDP checksum sums unchanged.
/// See Vendor/LocalTunnel/LICENSE and README.md for attribution.
nonisolated enum LoopbackPacket {
    static let interfaceIP = "10.7.1.1"
    static let peerIP = "10.7.0.1"
    private static let interfaceBytes: [UInt8] = [10, 7, 1, 1]
    private static let peerBytes: [UInt8] = [10, 7, 0, 1]

    static func reflect(_ packet: Data) -> Data? {
        var bytes = [UInt8](packet)
        guard bytes.count >= 20, bytes[0] >> 4 == 4 else { return nil }
        let headerLength = Int(bytes[0] & 0x0f) * 4
        let totalLength = Int(bytes[2]) * 256 + Int(bytes[3])
        guard headerLength >= 20, headerLength <= totalLength,
              totalLength == bytes.count else { return nil }
        let source = Array(bytes[12..<16])
        let destination = Array(bytes[16..<20])
        guard (source == interfaceBytes && destination == peerBytes)
                || (source == peerBytes && destination == interfaceBytes) else { return nil }
        bytes.replaceSubrange(12..<16, with: destination)
        bytes.replaceSubrange(16..<20, with: source)
        return Data(bytes)
    }
}
