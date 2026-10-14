// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.badge.mic")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.orange)
                            .frame(width: 78, height: 78)
                            .background(.orange.opacity(0.12), in: .circle)

                        Text("AirBeepSwap")
                            .font(.title2.bold())
                        Text(versionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "Maintained by Poner7"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Section(String(localized: "Maintainer")) {
                    Link("Poner7 · GitHub", destination: URL(string: "https://github.com/poner7/AirBeepSwap")!)
                }

                Section(String(localized: "Introduction")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "AirBeepSwap silences or replaces the call-recording disclosure tones. Original tones are backed up before the first change and can be restored at any time."))
                        Text(String(localized: "Supported system:") + " \(SystemCompatibility.supportedRangeDescription)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String(localized: "Legal Notice")) {
                    Text(String(localized: "Removing or replacing the disclosure tone means the other party is no longer told the call is being recorded. Many jurisdictions require informing all parties before recording. Use this app only on your own device and only where the law allows. You are solely responsible for complying with applicable laws."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(String(localized: "Credits")) {
                    VStack(alignment: .leading, spacing: 8) {
                        creditRow(name: "AirBeep", detail: "LinkPass888 · original iOS app (GPLv3)")
                        creditRow(name: "airlift", detail: "0xjohnnydev · AirTraffic sandbox escape research (MIT)")
                        creditRow(name: "AirliftSilence", detail: "YiHoooong · silent assets & replace protocol (MIT)")
                        creditRow(name: "AirCard", detail: "mak5er · Rust Airlift core")
                        creditRow(name: "placard", detail: "frs0n · iOS container access research")
                        creditRow(name: "LocalDevVPN / StosVPN", detail: "SideStore Team / jkcoxson · embedded tunnel uses adapted code")
                    }
                    .font(.footnote)
                }

                Section(String(localized: "Runtime Log")) {
                    Label(String(localized: "Logs include pairing, tunnel and AirLift file operations."), systemImage: "list.bullet.rectangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ShareLink(item: AirBeepSwapLog.shared.exportText()) {
                        Label(String(localized: "Export Log"), systemImage: "square.and.arrow.up")
                    }
                    Button(String(localized: "Clear Log"), role: .destructive) {
                        AirBeepSwapLog.shared.clear()
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle(String(localized: "About AirBeepSwap"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func creditRow(name: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).bold()
            Text(detail).foregroundStyle(.secondary)
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

#Preview {
    AboutView()
}
