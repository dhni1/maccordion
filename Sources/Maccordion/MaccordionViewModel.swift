import AppKit
import Foundation
import SwiftUI

@MainActor
final class MaccordionViewModel: ObservableObject {
    @Published private(set) var state = AccordionVoiceState(
        noteName: "-",
        angle: 0,
        pressure: 0,
        direction: "정지",
        status: "준비 중"
    )

    private let noteMap: [String: Int] = [
        "A": 60,
        "S": 62,
        "D": 64,
        "F": 65,
        "G": 67,
        "H": 69,
        "J": 71,
        "K": 72,
        "L": 74
    ]

    private let sensor: LidAngleSensor?
    private let engine: AccordionEngine?
    private var timer: Timer?
    private var lastAngle = 0.0
    private var activeKey: String?

    init() {
        do {
            self.sensor = try LidAngleSensor()
            self.engine = try AccordionEngine()
            try self.engine?.start()
            self.state = AccordionVoiceState(
                noteName: "-",
                angle: 0,
                pressure: 0,
                direction: "정지",
                status: "센서 연결됨"
            )
            startMonitoring()
        } catch {
            self.sensor = nil
            self.engine = nil
            self.state = AccordionVoiceState(
                noteName: "-",
                angle: 0,
                pressure: 0,
                direction: "정지",
                status: error.localizedDescription
            )
        }
    }

    func handleKeyDown(_ event: NSEvent) {
        guard let key = event.charactersIgnoringModifiers?.uppercased(),
              let midiNote = noteMap[key] else {
            return
        }

        activeKey = key
        engine?.noteOn(midiNote: midiNote, pressure: state.pressure, opening: state.direction == "열림")
        updateDisplayedNote(for: key)
    }

    func handleKeyUp(_ event: NSEvent) {
        guard let key = event.charactersIgnoringModifiers?.uppercased(),
              key == activeKey else {
            return
        }

        activeKey = nil
        engine?.noteOff()
        state = AccordionVoiceState(
            noteName: "-",
            angle: state.angle,
            pressure: state.pressure,
            direction: state.direction,
            status: state.status
        )
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollSensor()
            }
        }
    }

    private func pollSensor() {
        guard let sensor else {
            return
        }

        do {
            let angle = try sensor.readAngle()
            let delta = angle - lastAngle
            lastAngle = angle

            let rawPressure = min(abs(delta) / 8.0, 1.0)
            let smoothedPressure = state.pressure * 0.82 + rawPressure * 0.18
            let direction: String
            if delta > 0.35 {
                direction = "열림"
            } else if delta < -0.35 {
                direction = "닫힘"
            } else {
                direction = "정지"
            }

            if activeKey != nil {
                engine?.updatePressure(smoothedPressure, opening: direction != "닫힘")
            }

            state = AccordionVoiceState(
                noteName: activeKey ?? "-",
                angle: angle,
                pressure: smoothedPressure,
                direction: direction,
                status: "A S D F G H J K L 키로 연주"
            )
        } catch {
            state = AccordionVoiceState(
                noteName: activeKey ?? "-",
                angle: state.angle,
                pressure: state.pressure,
                direction: state.direction,
                status: error.localizedDescription
            )
        }
    }

    private func updateDisplayedNote(for key: String) {
        state = AccordionVoiceState(
            noteName: key,
            angle: state.angle,
            pressure: state.pressure,
            direction: state.direction,
            status: state.status
        )
    }
}
