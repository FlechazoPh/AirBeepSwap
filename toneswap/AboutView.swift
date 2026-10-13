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

                        Text("ToneSwap")
                            .font(.title2.bold())
                        Text(versionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Section(String(localized: "Introduction")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "ToneSwap silences or replaces the call-recording disclosure tones. Original tones are backed up before the first change and can be restored at any time."))
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
                    }
                    .font(.footnote)
                }

                Section(String(localized: "Runtime Log")) {
                    Label(String(localized: "Logs include pairing, tunnel and AirLift file operations."), systemImage: "list.bullet.rectangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ShareLink(item: ToneSwapLog.shared.exportText()) {
                        Label(String(localized: "Export Log"), systemImage: "square.and.arrow.up")
                    }
                    Button(String(localized: "Clear Log"), role: .destructive) {
                        ToneSwapLog.shared.clear()
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle(String(localized: "About ToneSwap"))
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
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

#Preview {
    AboutView()
}
