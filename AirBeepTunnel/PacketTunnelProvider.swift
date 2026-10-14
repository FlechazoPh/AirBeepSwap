// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import NetworkExtension

/// Embedded local tunnel adapted from LocalDevVPN / StosVPN's packet loop.
/// Copyright (c) 2025 SideStore Team. See Vendor/LocalTunnel/LICENSE.
final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let queue = DispatchQueue(label: "eu.flechazo.airbeepswap.local-tunnel")
    private var running = false

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let ipv4 = NEIPv4Settings(addresses: [LoopbackPacket.interfaceIP], subnetMasks: ["255.255.255.255"])
        ipv4.includedRoutes = [NEIPv4Route(destinationAddress: LoopbackPacket.peerIP, subnetMask: "255.255.255.255")]
        ipv4.excludedRoutes = [.default()]
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: LoopbackPacket.peerIP)
        settings.ipv4Settings = ipv4
        settings.mtu = 1500
        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self, error == nil else {
                completionHandler(error ?? NSError(domain: "AirBeepTunnel", code: 1))
                return
            }
            self.queue.async {
                self.running = true
                self.readPackets()
                completionHandler(nil)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        queue.async {
            self.running = false
            completionHandler()
        }
    }

    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self else { return }
            self.queue.async {
                guard self.running else { return }
                var reflected: [Data] = []
                var families: [NSNumber] = []
                for (packet, family) in zip(packets, protocols) where family.int32Value == AF_INET {
                    if let response = LoopbackPacket.reflect(packet) {
                        reflected.append(response)
                        families.append(family)
                    }
                }
                if !reflected.isEmpty {
                    self.packetFlow.writePackets(reflected, withProtocols: families)
                }
                self.readPackets()
            }
        }
    }
}
