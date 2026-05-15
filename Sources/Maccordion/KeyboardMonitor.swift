import AppKit
import Foundation

final class KeyboardMonitor {
    private var downMonitor: Any?
    private var upMonitor: Any?

    func start(onKeyDown: @escaping (NSEvent) -> Void, onKeyUp: @escaping (NSEvent) -> Void) {
        downMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            onKeyDown(event)
            return event
        }

        upMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            onKeyUp(event)
            return event
        }
    }

    func stop() {
        if let downMonitor {
            NSEvent.removeMonitor(downMonitor)
        }
        if let upMonitor {
            NSEvent.removeMonitor(upMonitor)
        }
    }

    deinit {
        stop()
    }
}
