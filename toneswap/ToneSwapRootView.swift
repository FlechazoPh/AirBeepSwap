import Combine
import SwiftUI

struct ToneSwapRootView: View {
    @StateObject private var service = CallRecordingToneService.shared
    @State private var showingAbout = false
    @State private var showingAirliftSetup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    statusCard
                    if let busyMessage = service.busyMessage {
                        busyWarning(message: busyMessage)
                    }
                    if service.needsAirliftSetup {
                        airliftSetupCard
                    }
                    toneToggle
                    customTonesSection
                    restoreSection
                    details
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ToneSwap")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About")
                }
            }
        }
        .task {
            await service.refresh()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingAirliftSetup, onDismiss: {
            Task { await service.refresh() }
        }) {
            AirliftSetupView()
        }
        .alert(
            String(localized: "Operation Failed"),
            isPresented: Binding(
                get: { service.lastError != nil },
                set: { presented in
                    if !presented {
                        service.clearError()
                    }
                }
            )
        ) {
            Button(String(localized: "OK")) {
                service.clearError()
            }
        } message: {
            Text(service.lastError ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 88, height: 88)
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(String(localized: "Call Recording Tone"))
                .font(.title2.bold())
            Text(String(localized: "Choose the disclosure sound played when call recording starts and stops."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: modeSymbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(modeColor)
                .frame(width: 48, height: 48)
                .background(modeColor.opacity(0.12), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(modeTitle)
                    .font(.headline)
                Text(modeDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if service.isBusy {
                ProgressView()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var toneToggle: some View {
        VStack(spacing: 14) {
            Toggle(
                isOn: Binding(
                    get: { service.mode == .silentTone },
                    set: { enabled in
                        if enabled {
                            Task { await service.applySilentTone() }
                        } else {
                            Task { await service.restoreSystemTone() }
                        }
                    }
                )
            ) {
                Label(String(localized: "Silence recording tone"), systemImage: "speaker.slash.fill")
                    .font(.headline)
            }
            .tint(.orange)
            .disabled(service.isBusy || service.mode == .checking || service.mode == .unavailable)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var customTonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Custom tones"), systemImage: "music.note")
                .font(.headline)
                .padding(.horizontal, 4)

            Text(String(localized: "Replace each tone with your own audio. Files are converted to the system format automatically."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            CustomToneCard(kind: .start, service: service)
            CustomToneCard(kind: .stop, service: service)
        }
    }

    private var restoreSection: some View {
        Button {
            Task { await service.restoreSystemTone() }
        } label: {
            Label(String(localized: "Restore original tones"), systemImage: "arrow.uturn.backward")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(service.isBusy || service.mode == .checking || service.mode == .unavailable)
    }

    private func busyWarning(message: String) -> some View {
        Label {
            Text(message)
                .font(.headline)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.red.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private var airliftSetupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Airlift Setup Required"), systemImage: "link.badge.plus")
                .font(.headline)

            Text(String(localized: "Pair this iPhone and connect LocalDevVPN to allow ToneSwap to access the recording tone files."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingAirliftSetup = true
            } label: {
                Label(String(localized: "Open Airlift Setup"), systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Original tones are backed up before the first change."), systemImage: "checkmark.shield")
            Label(String(localized: "Start and stop sounds are replaced with equal-length silence."), systemImage: "waveform.slash")
            Label(String(localized: "Changing the system language will force the original tones back."), systemImage: "globe")
            Label(String(localized: "Removing or replacing the disclosure tone means the other party is no longer told the call is being recorded. Use only where the law allows."), systemImage: "exclamationmark.triangle")
            Label(String(localized: "This app relies on non-public system behavior. Use it carefully."), systemImage: "exclamationmark.triangle")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeTitle: String {
        switch service.mode {
        case .checking:
            String(localized: "Checking...")
        case .systemTone:
            String(localized: "System Original")
        case .silentTone:
            String(localized: "Silent")
        case .customTone:
            String(localized: "Custom Tones")
        case .unavailable:
            String(localized: "Unavailable")
        }
    }

    private var modeDetail: String {
        switch service.mode {
        case .checking:
            String(localized: "Reading the current disclosure tones.")
        case .systemTone:
            String(localized: "The iPhone's original recording disclosure tones are active.")
        case .silentTone:
            String(localized: "The recording disclosure tones are replaced with silence.")
        case .customTone:
            customDetail
        case .unavailable:
            service.statusDetail ?? String(localized: "This device or system version does not support the required access.")
        }
    }

    private var customDetail: String {
        let parts = ToneKind.allCases.map { kind -> String in
            let name = kind == .start ? String(localized: "Start") : String(localized: "Stop")
            if let meta = service.customMetas[kind] {
                return "\(name): \(meta.displayName)"
            }
            return "\(name): \(String(localized: "System Original"))"
        }
        return parts.joined(separator: " · ")
    }

    private var modeSymbol: String {
        switch service.mode {
        case .checking:
            "hourglass"
        case .systemTone:
            "speaker.wave.2.fill"
        case .silentTone:
            "speaker.slash.fill"
        case .customTone:
            "music.note"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }

    private var modeColor: Color {
        switch service.mode {
        case .checking:
            .secondary
        case .systemTone:
            .blue
        case .silentTone:
            .orange
        case .customTone:
            .green
        case .unavailable:
            .red
        }
    }
}

#Preview {
    ToneSwapRootView()
}
