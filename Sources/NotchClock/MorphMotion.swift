import AppKit

/// A critically damped spring preserves position and velocity when hover intent reverses.
struct MorphMotion {
    private(set) var value: CGFloat = 0
    private(set) var velocity: CGFloat = 0
    var target: CGFloat = 0
    var isAtRest: Bool { abs(value - target) < 0.0005 && abs(velocity) < 0.005 }

    mutating func advance(by elapsed: TimeInterval) {
        var remaining = min(max(0, elapsed), 0.1)
        while remaining > 0 {
            let dt = min(remaining, 1 / 120)
            velocity += ((target - value) * 256 - velocity * 32) * dt
            value = min(1, max(0, value + velocity * dt))
            remaining -= dt
        }
        if isAtRest { value = target; velocity = 0 }
    }
    mutating func snap(to target: CGFloat) { self.target = target; value = target; velocity = 0 }
}

@MainActor
final class MorphTransition {
    private(set) var motion = MorphMotion()
    private var timer: Timer?
    private var previousTime = ProcessInfo.processInfo.systemUptime
    var onUpdate: ((CGFloat) -> Void)?

    func move(to target: CGFloat, animated: Bool) {
        motion.target = target
        guard animated else {
            timer?.invalidate(); timer = nil
            motion.snap(to: target)
            onUpdate?(target)
            return
        }
        guard timer == nil, !motion.isAtRest else { return }
        previousTime = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    private func step() {
        let now = ProcessInfo.processInfo.systemUptime
        motion.advance(by: now - previousTime)
        previousTime = now
        onUpdate?(motion.value)
        if motion.isAtRest { timer?.invalidate(); timer = nil }
    }
    func stop() { timer?.invalidate(); timer = nil }
}
