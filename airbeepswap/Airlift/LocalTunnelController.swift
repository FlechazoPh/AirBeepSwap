// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import Combine
import Foundation
import NetworkExtension

@MainActor
final class LocalTunnelController: ObservableObject {
    static let shared = LocalTunnelController()
    @Published private(set) var status: NEVPNStatus = .invalid
    @Published private(set) var isBusy = false
    @Published private(set) var lastError: String?
    private var manager: NETunnelProviderManager?
    private var observer: NSObjectProtocol?

    var isConnected: Bool { status == .connected }

    var statusText: String {
        switch status {
        case .connected: String(localized: "Local tunnel connected")
        case .connecting, .reasserting: String(localized: "Connecting local tunnel…")
        case .disconnecting: String(localized: "Disconnecting local tunnel…")
        default: String(localized: "Local tunnel disconnected")
        }
    }

    private init() {
        observer = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.updateStatus() }
        }
    }

    /// Resolve the embedded extension's actual ID, including after re-signing.
    private var providerBundleIdentifier: String {
        if let plugins = Bundle.main.builtInPlugInsURL,
           let extensionBundle = Bundle(url: plugins.appendingPathComponent("AirBeepTunnel.appex")),
           let identifier = extensionBundle.bundleIdentifier {
            return identifier
        }
        return (Bundle.main.bundleIdentifier ?? "eu.flechazo.airbeepswap") + ".tunnel"
    }

    private func loadManager() async throws -> NETunnelProviderManager {
        if let manager { return manager }
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager = managers.first {
            ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == providerBundleIdentifier
        } ?? NETunnelProviderManager()
        self.manager = manager
        updateStatus()
        return manager
    }

    func refreshStatus() async {
        #if targetEnvironment(simulator)
        status = .invalid
        #else
        do {
            _ = try await loadManager()
            updateStatus()
        } catch {
            lastError = configurationError(error).localizedDescription
        }
        #endif
    }

    func ensureConnected() async throws {
        await refreshStatus()
        if !isConnected { try await connect() }
    }

    func connect() async throws {
        guard !isBusy else { throw LocalTunnelError.busy }
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            #if targetEnvironment(simulator)
            throw LocalTunnelError.physicalDeviceRequired
            #else
            let manager = try await loadManager()
            if manager.connection.status == .connected { updateStatus(); return }
            let configuration = NETunnelProviderProtocol()
            configuration.providerBundleIdentifier = providerBundleIdentifier
            configuration.serverAddress = "AirBeepSwap Local Tunnel"
            configuration.disconnectOnSleep = false
            manager.protocolConfiguration = configuration
            manager.localizedDescription = "AirBeepSwap"
            manager.isEnabled = true
            manager.isOnDemandEnabled = false
            // iOS presents its VPN consent sheet the first time this is saved.
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            try manager.connection.startVPNTunnel()
            let deadline = ContinuousClock.now.advanced(by: .seconds(15))
            repeat {
                try await Task.sleep(for: .milliseconds(150))
                updateStatus()
                if isConnected {
                    AirBeepSwapLog.shared.append("built-in local tunnel connected")
                    return
                }
            } while ContinuousClock.now < deadline
            manager.connection.stopVPNTunnel()
            throw LocalTunnelError.connectionFailed
            #endif
        } catch {
            updateStatus()
            let reported = configurationError(error)
            lastError = reported.localizedDescription
            AirBeepSwapLog.shared.append("built-in local tunnel error: \(reported.localizedDescription)")
            throw reported
        }
    }

    func disconnect() {
        guard !isBusy else { return }
        manager?.connection.stopVPNTunnel()
        updateStatus()
    }

    private func updateStatus() {
        status = manager?.connection.status ?? .invalid
    }

    private func configurationError(_ error: Error) -> Error {
        if error is LocalTunnelError || error is CancellationError { return error }
        return LocalTunnelError.configurationFailed(error.localizedDescription)
    }
}

enum LocalTunnelError: LocalizedError {
    case busy
    case physicalDeviceRequired
    case connectionFailed
    case configurationFailed(String)

    var errorDescription: String? {
        switch self {
        case .busy: String(localized: "A local tunnel operation is already in progress.")
        case .physicalDeviceRequired: String(localized: "The built-in tunnel requires a physical iPhone and Network Extension signing permissions.")
        case .connectionFailed: String(localized: "The built-in tunnel did not connect. Check that both the app and its extension are signed with Network Extension permissions.")
        case .configurationFailed(let reason):
            String(format: String(localized: "Could not configure the built-in tunnel: %@. Both the app and its extension need Network Extension signing permissions."), reason)
        }
    }
}
