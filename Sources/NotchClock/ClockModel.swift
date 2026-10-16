import Foundation

struct HandAngles {
    let hour: Double
    let minute: Double
    let second: Double

    init(date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let seconds = Double(parts.second ?? 0)
        let minutes = Double(parts.minute ?? 0) + seconds / 60
        hour = (Double((parts.hour ?? 0) % 12) + minutes / 60) * .pi / 6
        minute = minutes * .pi / 30
        second = seconds * .pi / 30
    }
}

