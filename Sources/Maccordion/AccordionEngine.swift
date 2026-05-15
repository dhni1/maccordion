import AVFoundation
import Foundation

struct AccordionVoiceState {
    let noteName: String
    let angle: Double
    let pressure: Double
    let direction: String
    let status: String
}

final class AccordionEngine {
    private struct Voice {
        var frequency: Double
        var amplitude: Double = 0
        var phase: Double = 0
        var isActive = false
    }

    private let sampleRate: Double = 48_000
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private var voice = Voice(frequency: 440)
    private var currentTargetAmplitude = 0.0
    private var currentBrightness = 0.4

    init() throws {
        try configureAudio()
    }

    func start() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    func stop() {
        engine.stop()
    }

    func noteOn(midiNote: Int, pressure: Double, opening: Bool) {
        voice.frequency = midiToHz(midiNote)
        voice.isActive = true
        updatePressure(pressure, opening: opening)
    }

    func noteOff() {
        voice.isActive = false
        currentTargetAmplitude = 0
    }

    func updatePressure(_ pressure: Double, opening: Bool) {
        currentTargetAmplitude = min(max(pressure, 0), 1) * 0.25
        currentBrightness = opening ? 0.62 : 0.28
    }

    private func configureAudio() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0 ..< Int(frameCount) {
                let sample = self.nextSample()

                for buffer in ablPointer {
                    let channel = buffer.mData!.assumingMemoryBound(to: Float.self)
                    channel[frame] = sample
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1
    }

    private func nextSample() -> Float {
        let slew = 0.003
        voice.amplitude += (currentTargetAmplitude - voice.amplitude) * slew

        if voice.amplitude < 0.0001 {
            voice.amplitude = 0
        }

        if !voice.isActive && voice.amplitude == 0 {
            return 0
        }

        let increment = (2 * Double.pi * voice.frequency) / sampleRate
        voice.phase += increment
        if voice.phase >= 2 * Double.pi {
            voice.phase -= 2 * Double.pi
        }

        let fundamental = sin(voice.phase)
        let reed2 = sin(voice.phase * 2.01) * 0.35
        let reed3 = sin(voice.phase * 3.0) * currentBrightness * 0.25
        let noise = (Double.random(in: -1 ... 1)) * voice.amplitude * 0.015
        let sample = (fundamental + reed2 + reed3) * voice.amplitude + noise

        return Float(sample)
    }

    private func midiToHz(_ midiNote: Int) -> Double {
        440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
    }
}
