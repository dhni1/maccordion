import Foundation
import IOKit.hid

enum LidAngleSensorError: LocalizedError {
    case deviceUnavailable
    case openFailed(IOReturn)
    case readFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            return "힌지 센서를 찾지 못했습니다. 지원되지 않는 맥북일 수 있습니다."
        case .openFailed(let code):
            return "힌지 센서를 열지 못했습니다. IOReturn=\(code)"
        case .readFailed(let code):
            return "힌지 센서 값을 읽지 못했습니다. IOReturn=\(code)"
        }
    }
}

final class LidAngleSensor {
    private let manager: IOHIDManager
    private var device: IOHIDDevice?

    init() throws {
        self.manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        try self.connect()
    }

    deinit {
        if let device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    func readAngle() throws -> Double {
        guard let device else {
            throw LidAngleSensorError.deviceUnavailable
        }

        var report = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(report.count)
        let result = report.withUnsafeMutableBytes { buffer in
            IOHIDDeviceGetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(1),
                buffer.bindMemory(to: UInt8.self).baseAddress!,
                &length
            )
        }

        guard result == kIOReturnSuccess else {
            throw LidAngleSensorError.readFailed(result)
        }

        guard length >= 3 else {
            throw LidAngleSensorError.deviceUnavailable
        }

        let value = UInt16(report[1]) | (UInt16(report[2]) << 8)
        return Double(value)
    }

    private func connect() throws {
        let matching = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDProductIDKey as String: 0x8104
        ] as CFDictionary

        IOHIDManagerSetDeviceMatching(manager, matching)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            throw LidAngleSensorError.openFailed(openResult)
        }

        guard let devices = IOHIDManagerCopyDevices(manager) else {
            throw LidAngleSensorError.deviceUnavailable
        }

        let count = CFSetGetCount(devices)
        guard count > 0 else {
            throw LidAngleSensorError.deviceUnavailable
        }

        let values = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: count)
        defer { values.deallocate() }
        CFSetGetValues(devices, values)

        for index in 0 ..< count {
            guard let rawDevice = values[index] else {
                continue
            }

            let candidate = unsafeBitCast(rawDevice, to: IOHIDDevice.self)
            let result = IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
            guard result == kIOReturnSuccess else {
                continue
            }

            var report = [UInt8](repeating: 0, count: 8)
            var length = CFIndex(report.count)
            let readResult = report.withUnsafeMutableBytes { buffer in
                IOHIDDeviceGetReport(
                    candidate,
                    kIOHIDReportTypeFeature,
                    CFIndex(1),
                    buffer.bindMemory(to: UInt8.self).baseAddress!,
                    &length
                )
            }

            if readResult == kIOReturnSuccess, length >= 3 {
                self.device = candidate
                return
            }

            IOHIDDeviceClose(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        throw LidAngleSensorError.deviceUnavailable
    }
}
