// AirBeepSwap — maintained by Poner7.
// https://github.com/poner7/AirBeepSwap

import AVFoundation
import Foundation

/// Which disclosure tone a custom audio file targets.
nonisolated enum ToneKind: String, CaseIterable, Sendable {
    case start
    case stop

    /// Index into CallRecordingToneService's tone file list.
    var fileIndex: Int {
        switch self {
        case .start: return 0
        case .stop: return 1
        }
    }

    var fileExtension: String {
        switch self {
        case .start: return "m4a"
        case .stop: return "caf"
        }
    }

    /// The original system tone duration, used as a reference in the UI.
    /// (StartDisclosureWithTone.m4a ≈ 1.834s, StopDisclosure.caf ≈ 1.770s —
    /// measured from the AirliftSilence research.)
    var originalDuration: TimeInterval {
        switch self {
        case .start: return 1.834
        case .stop: return 1.770
        }
    }
}

enum ToneAudioProcessorError: LocalizedError {
    case cannotRead(String)
    case emptyAudio
    case tooLong(TimeInterval)
    case conversionFailed(String)
    case cannotWrite(String)

    var errorDescription: String? {
        switch self {
        case .cannotRead(let name):
            String(format: String(localized: "Cannot read audio file %@: unsupported or protected format."), name)
        case .emptyAudio:
            String(localized: "The selected audio contains no sound.")
        case .tooLong(let seconds):
            String(format: String(localized: "Audio is too long (%.0fs). Please choose something under 120 seconds."), seconds)
        case .conversionFailed(let reason):
            String(format: String(localized: "Audio conversion failed: %@"), reason)
        case .cannotWrite(let reason):
            String(format: String(localized: "Cannot write converted audio: %@"), reason)
        }
    }
}

/// An uploaded audio file, transcoded to the exact format iOS expects for the
/// target disclosure tone (AAC 44.1kHz mono .m4a for the start tone,
/// PCM s16le 48kHz mono .caf for the stop tone), ready to be written to the device.
struct PreparedTone: Sendable {
    let kind: ToneKind
    let data: Data
    let duration: TimeInterval
    let sourceDuration: TimeInterval
    let displayName: String
    let peaks: [Float]
}

nonisolated enum ToneAudioProcessor {
    /// Hard cap so a pathological input cannot exhaust memory during conversion.
    private static let maxDuration: TimeInterval = 120

    static func prepare(sourceURL: URL, kind: ToneKind) throws -> PreparedTone {
        let displayName = sourceURL.lastPathComponent
        let source: AVAudioFile
        do {
            source = try AVAudioFile(forReading: sourceURL)
        } catch {
            throw ToneAudioProcessorError.cannotRead(displayName)
        }
        let srcFormat = source.processingFormat
        guard source.length > 0 else { throw ToneAudioProcessorError.emptyAudio }
        let sourceDuration = Double(source.length) / srcFormat.sampleRate
        guard sourceDuration <= maxDuration else { throw ToneAudioProcessorError.tooLong(sourceDuration) }

        // Intermediate PCM: target sample rate / mono, float32 non-interleaved.
        let targetRate: Double = kind == .start ? 44100 : 48000
        guard let pcmFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetRate,
            channels: 1,
            interleaved: false
        ) else {
            throw ToneAudioProcessorError.conversionFailed("pcm format")
        }

        let frameCount = AVAudioFrameCount(min(Double(source.length), maxDuration * srcFormat.sampleRate))
        guard let inBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: frameCount) else {
            throw ToneAudioProcessorError.conversionFailed("input buffer")
        }
        do {
            try source.read(into: inBuffer)
        } catch {
            throw ToneAudioProcessorError.cannotRead(displayName)
        }
        guard inBuffer.frameLength > 0 else { throw ToneAudioProcessorError.emptyAudio }

        guard let converter = AVAudioConverter(from: srcFormat, to: pcmFormat) else {
            throw ToneAudioProcessorError.conversionFailed("converter")
        }
        let outCapacity = AVAudioFrameCount(Double(inBuffer.frameLength) * targetRate / srcFormat.sampleRate) + 1024
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: outCapacity) else {
            throw ToneAudioProcessorError.conversionFailed("output buffer")
        }
        try convertOneShot(converter: converter, input: inBuffer, output: pcmBuffer)
        guard pcmBuffer.frameLength > 0 else { throw ToneAudioProcessorError.emptyAudio }

        let duration = Double(pcmBuffer.frameLength) / targetRate
        let peaks = waveformPeaks(from: pcmBuffer, buckets: 120)

        // Encode to the container iOS expects.
        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("airbeepswap-\(kind.rawValue)-\(UUID().uuidString).\(kind.fileExtension)")
        let dstFile: AVAudioFile
        do {
            switch kind {
            case .start:
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 64000,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ]
                dstFile = try AVAudioFile(
                    forWriting: outURL,
                    settings: settings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
                try dstFile.write(from: pcmBuffer)
            case .stop:
                guard let int16 = AVAudioFormat(
                    commonFormat: .pcmFormatInt16,
                    sampleRate: 48000,
                    channels: 1,
                    interleaved: true
                ) else {
                    throw ToneAudioProcessorError.conversionFailed("pcm16 format")
                }
                guard let int16Buffer = AVAudioPCMBuffer(pcmFormat: int16, frameCapacity: pcmBuffer.frameCapacity) else {
                    throw ToneAudioProcessorError.conversionFailed("pcm16 buffer")
                }
                guard let downConverter = AVAudioConverter(from: pcmFormat, to: int16) else {
                    throw ToneAudioProcessorError.conversionFailed("pcm16 converter")
                }
                try convertOneShot(converter: downConverter, input: pcmBuffer, output: int16Buffer)
                dstFile = try AVAudioFile(forWriting: outURL, settings: int16.settings)
                try dstFile.write(from: int16Buffer)
            }
        } catch let error as ToneAudioProcessorError {
            throw error
        } catch {
            throw ToneAudioProcessorError.cannotWrite(error.localizedDescription)
        }

        let data: Data
        do {
            data = try Data(contentsOf: outURL)
        } catch {
            throw ToneAudioProcessorError.cannotWrite(error.localizedDescription)
        }
        try? FileManager.default.removeItem(at: outURL)

        return PreparedTone(
            kind: kind,
            data: data,
            duration: duration,
            sourceDuration: sourceDuration,
            displayName: displayName,
            peaks: peaks
        )
    }

    /// One-shot conversion of a fully-buffered input. The output buffer must be
    /// sized to hold the entire converted input (callers over-provision it).
    private static func convertOneShot(
        converter: AVAudioConverter,
        input: AVAudioPCMBuffer,
        output: AVAudioPCMBuffer
    ) throws {
        var provided = false
        var status: AVAudioConverterOutputStatus = .haveData
        while status == .haveData {
            var convError: NSError?
            status = converter.convert(to: output, error: &convError) { _, outStatus in
                if provided {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                provided = true
                outStatus.pointee = .haveData
                return input
            }
            if let convError {
                throw ToneAudioProcessorError.conversionFailed(convError.localizedDescription)
            }
            if status == .error {
                throw ToneAudioProcessorError.conversionFailed("converter error")
            }
        }
    }

    /// Downsamples a mono float32 buffer to per-bucket peak amplitudes in 0...1.
    static func waveformPeaks(from buffer: AVAudioPCMBuffer, buckets: Int) -> [Float] {
        guard let channel = buffer.floatChannelData?[0], buffer.frameLength > 0, buckets > 0 else {
            return []
        }
        let total = Int(buffer.frameLength)
        var peaks = [Float](repeating: 0, count: buckets)
        let perBucket = max(1, total / buckets)
        var globalMax: Float = 0
        for b in 0..<buckets {
            let start = b * perBucket
            let end = min(start + perBucket, total)
            var peak: Float = 0
            var i = start
            while i < end {
                let v = abs(channel[i])
                if v > peak { peak = v }
                i += 1
            }
            peaks[b] = peak
            if peak > globalMax { globalMax = peak }
        }
        guard globalMax > 0 else { return peaks }
        return peaks.map { min(1, $0 / globalMax) }
    }
}
