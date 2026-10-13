import SwiftUI

/// Renders normalized waveform peaks as vertical bars, with duration labels.
struct WaveformView: View {
    let peaks: [Float]
    let duration: TimeInterval
    var accent: Color = .orange

    var body: some View {
        VStack(spacing: 6) {
            Canvas { context, size in
                guard !peaks.isEmpty else { return }
                let barWidth = size.width / CGFloat(peaks.count)
                let drawWidth = max(1, barWidth * 0.62)
                for (index, peak) in peaks.enumerated() {
                    let height = max(2, CGFloat(peak) * size.height)
                    let x = CGFloat(index) * barWidth + (barWidth - drawWidth) / 2
                    let rect = CGRect(
                        x: x,
                        y: (size.height - height) / 2,
                        width: drawWidth,
                        height: height
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: drawWidth / 2), with: .color(accent))
                }
            }
            .frame(height: 72)
            .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 10))

            HStack {
                Text(formattedDuration(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(localized: "preview ready"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let total = max(0, interval)
        let minutes = Int(total) / 60
        let seconds = total - Double(minutes * 60)
        if minutes > 0 {
            return String(format: "%d:%04.1f", minutes, seconds)
        }
        return String(format: "%.1fs", seconds)
    }
}

/// Compares the original system tone length with the replacement's length.
struct DurationCompareView: View {
    let original: TimeInterval
    let replacement: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            durationPill(
                title: String(localized: "Original"),
                value: original,
                color: .blue
            )
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            durationPill(
                title: String(localized: "Replacement"),
                value: replacement,
                color: replacement > original * 3 ? .red : .orange
            )
            Spacer()
        }
        if replacement > original * 3 {
            Label(
                String(localized: "Much longer than the original — the tone will play in full each time."),
                systemImage: "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func durationPill(title: String, value: TimeInterval, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1fs", value))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: .capsule)
    }
}

#Preview {
    VStack(spacing: 16) {
        WaveformView(peaks: (0..<120).map { Float(abs(sin(Double($0) * 0.35))) }, duration: 2.4)
        DurationCompareView(original: 1.8, replacement: 12.5)
    }
    .padding()
}
