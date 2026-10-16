import AppKit
import Darwin

/// An opt-in development probe. Normal launches do not allocate its sampling timer.
@MainActor
final class PerformanceProbe: NSObject {
    private let output: URL
    private let toggle: () -> Void
    private var timer: Timer?
    private var startTime: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    private var lastCPU: Double = 0
    private var rows = ["elapsed_seconds,phase,cpu_percent_one_core,rss_mib,physical_footprint_mib"]
    private var sample = 0

    init(output: URL, toggle: @escaping () -> Void) {
        self.output = output
        self.toggle = toggle
    }

    func start() {
        startTime = ProcessInfo.processInfo.systemUptime
        lastTime = startTime
        lastCPU = cpuTime()
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func tick() {
        sample += 1
        let now = ProcessInfo.processInfo.systemUptime
        let cpu = cpuTime()
        let percent = 100 * (cpu - lastCPU) / (now - lastTime)
        let phase = sample <= 20 ? "compact" : sample <= 40 ? "expanded" : sample <= 52 ? "transitions" : "recovered_compact"
        rows.append(String(format: "%.3f,%@,%.3f,%.3f,%.3f", now - startTime, phase, percent, residentMiB(), physicalFootprintMiB()))
        lastTime = now
        lastCPU = cpu
        if sample == 20 || sample == 40 || (sample > 40 && sample <= 52) { toggle() }
        if sample == 72 {
            timer?.invalidate()
            try? FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? (rows.joined(separator: "\n") + "\n").write(to: output, atomically: true, encoding: .utf8)
            NSApp.terminate(nil)
        }
    }

    private func cpuTime() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) +
            Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
    }


    private func physicalFootprintMiB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

    private func residentMiB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : -1
    }
}
