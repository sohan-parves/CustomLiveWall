import Cocoa
import IOKit.ps

final class BatteryMonitor {

    static let shared = BatteryMonitor()

    var onPowerSourceChanged: ((Bool) -> Void)? // true if on battery

    private var timer: Timer?

    func start() {
        // Polling approach for simplicity; can be replaced with IOPS notifications
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.notify()
        }
        RunLoop.main.add(timer!, forMode: .common)
        notify()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func notify() {
        onPowerSourceChanged?(isOnBattery())
    }

    private func isOnBattery() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return false }
        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any],
               let type = desc[kIOPSPowerSourceStateKey] as? String {
                if type == kIOPSBatteryPowerValue { return true }
            }
        }
        return false
    }
}
