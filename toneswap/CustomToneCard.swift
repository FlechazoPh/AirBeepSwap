import AVFoundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

/// Simple one-shot preview player for transcoded tone audio.
@MainActor
final class PreviewPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(data: Data) {
        if isPlaying {
            stop()
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            self.player = player
            player.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        self.player = nil
    }
}

/// Per-tone card: pick a local audio file, see its waveform and duration,
/// preview it, and replace the disclosure tone with it.
struct CustomToneCard: View {
    let kind: ToneKind
    @ObservedObject var service: CallRecordingToneService

    @State private var showImporter = false
    @State private var prepared: PreparedTone?
    @State private var isProcessing = false
    @State private var processError: String?
    @StateObject private var preview = PreviewPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(kindTitle, systemImage: kind == .start ? "phone.arrow.up.right" : "phone.arrow.down.left")
                    .font(.headline)
                Spacer()
                Text(service.stateLabel(for: kind))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stateColor.opacity(0.12), in: .capsule)
                    .foregroundStyle(stateColor)
                    .lineLimit(1)
            }

            Text(kindSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isProcessing {
                HStack {
                    ProgressView()
                    Text(String(localized: "Converting audio…"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let tone = prepared {
                WaveformView(peaks: tone.peaks, duration: tone.duration)
                DurationCompareView(original: kind.originalDuration, replacement: tone.duration)
                Text(tone.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack {
                    Button {
                        preview.toggle(data: tone.data)
                    } label: {
                        Label(
                            preview.isPlaying ? String(localized: "Stop") : String(localized: "Preview"),
                            systemImage: preview.isPlaying ? "stop.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(service.isBusy)

                    Spacer()

                    Button {
                        Task {
                            await service.applyCustomTone(
                                kind: kind,
                                data: tone.data,
                                meta: CustomToneMeta(displayName: tone.displayName, duration: tone.duration)
                            )
                            if service.lastError == nil {
                                prepared = nil
                            }
                        }
                    } label: {
                        Label(String(localized: "Replace with this audio"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(service.isBusy)
                }
            }

            HStack {
                Button {
                    preview.stop()
                    showImporter = true
                } label: {
                    Label(
                        prepared == nil ? String(localized: "Choose audio file") : String(localized: "Choose another"),
                        systemImage: "folder"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(service.isBusy || isProcessing)

                Spacer()

                if service.customMetas[kind] != nil, service.mode == .customTone {
                    Button(String(localized: "Restore original")) {
                        Task { await service.restoreSystemTone() }
                    }
                    .font(.caption)
                    .disabled(service.isBusy)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handlePicked(url: url)
                }
            case .failure(let error):
                processError = error.localizedDescription
            }
        }
        .alert(
            String(localized: "Audio Error"),
            isPresented: Binding(
                get: { processError != nil },
                set: { if !$0 { processError = nil } }
            )
        ) {
            Button(String(localized: "OK")) { processError = nil }
        } message: {
            Text(processError ?? "")
        }
        .onDisappear {
            preview.stop()
        }
    }

    private var kindTitle: String {
        switch kind {
        case .start: return String(localized: "Recording-start tone")
        case .stop: return String(localized: "Recording-stop tone")
        }
    }

    private var kindSubtitle: String {
        switch kind {
        case .start: return String(localized: "Played when call recording starts.")
        case .stop: return String(localized: "Played when call recording stops.")
        }
    }

    private var stateColor: Color {
        switch service.mode {
        case .silentTone: return .orange
        case .customTone: return service.customMetas[kind] != nil ? .green : .blue
        default: return .blue
        }
    }

    private func handlePicked(url: URL) {
        isProcessing = true
        processError = nil
        prepared = nil
        preview.stop()
        let kind = kind
        Task {
            do {
                let localURL = try copyToTemp(url: url)
                defer { try? FileManager.default.removeItem(at: localURL) }
                let tone = try await Task.detached(priority: .userInitiated) {
                    try ToneAudioProcessor.prepare(sourceURL: localURL, kind: kind)
                }.value
                await MainActor.run {
                    self.prepared = tone
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.processError = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }

    private func copyToTemp(url: URL) throws -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let ext = url.pathExtension.isEmpty ? "audio" : url.pathExtension
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("toneswap-import-\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }
}

#Preview {
    CustomToneCard(kind: .start, service: CallRecordingToneService.shared)
        .padding()
}
