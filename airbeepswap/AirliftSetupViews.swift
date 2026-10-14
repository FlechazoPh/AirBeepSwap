// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import SwiftUI
import UIKit
import Network
import Combine

@MainActor
final class AirliftWiFiMonitor: ObservableObject {
    enum Status {
        case checking
        case connected
        case disconnected
    }

    @Published private(set) var status: Status = .checking

    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let queue = DispatchQueue(label: "me.ssus.airbeep.airlift.wifi-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status: Status = path.status == .satisfied ? .connected : .disconnected
            DispatchQueue.main.async {
                self?.status = status
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}


struct AirliftWiFiCheckingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Checking Wi-Fi…")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
    }
}

struct AirliftWiFiRequiredView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Wi-Fi Required")
                .font(.largeTitle.bold())
            Text("Connect to Wi-Fi to use pairing and the built-in local tunnel.")
                .foregroundStyle(.secondary)
            Text("Connect this iPhone to a Wi-Fi network to continue. AirBeepSwap will continue automatically once Wi-Fi is available.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
    }
}

struct AirliftPairingView: View {
    let running: Bool
    let pin: String?
    let error: String?
    let onStart: () -> Void
    let onImportPairingFile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Pair this iPhone")
                .font(.largeTitle.bold())
            Text("Start pairing, then open Settings › Privacy & Security › Developer Mode › Pair with AirBeepSwap.")
                .foregroundStyle(.secondary)
            if let pin {
                Text(pin).font(.largeTitle.monospacedDigit())
            }
            if let error {
                Text(error).foregroundStyle(.red)
            }
            Spacer()
            Button(action: onStart) {
                if running {
                    ProgressView("Waiting for pairing…")
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Start pairing")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(running)

            Button(action: onImportPairingFile) {
                Label("Import pairing file", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(running)
        }
        .padding(24)
    }
}

struct AirliftTunnelView: View {
    let connectionError: String?
    let checking: Bool
    let connecting: Bool
    let isConnected: Bool
    let statusText: String
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onCheck: () -> Void
    let onPairAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Image(systemName: "network")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Connect built-in tunnel")
                .font(.largeTitle.bold())
            Text("AirBeepSwap includes the local tunnel. Tap Connect and allow iOS to add the VPN configuration.")
                .foregroundStyle(.secondary)
            Label(statusText, systemImage: isConnected ? "checkmark.circle.fill" : "network")
                .foregroundStyle(isConnected ? .green : .secondary)
            if isConnected {
                Button("Disconnect tunnel", action: onDisconnect)
                    .buttonStyle(.bordered)
                    .disabled(checking || connecting)
            } else {
                Button(action: onConnect) {
                    if connecting { ProgressView("Connecting local tunnel…") }
                    else { Text("Connect tunnel") }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(connecting || checking)
            }
            if let connectionError {
                Text(connectionError).foregroundStyle(.red)
                Button("Pair again", action: onPairAgain)
                    .font(.footnote)
            }
            Spacer()
            Button(action: onCheck) {
                if checking {
                    ProgressView("Checking connection…")
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Check and enter")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(checking || connecting || !isConnected)
        }
        .padding(24)
    }

}

#Preview("Wi-Fi Required") {
    AirliftWiFiRequiredView()
}

#Preview("Pairing") {
    AirliftPairingView(running: false, pin: nil, error: nil, onStart: {}, onImportPairingFile: {})
}

#Preview("Built-in tunnel") {
    AirliftTunnelView(connectionError: nil, checking: false, connecting: false, isConnected: false,
                      statusText: "Local tunnel disconnected", onConnect: {}, onDisconnect: {}, onCheck: {}, onPairAgain: {})
}
