import Foundation

/// Native design recipes are separate from component data and color palettes.
enum VisualFamily: String, Codable, CaseIterable, Sendable {
    case wavy
    case counter

    var title: String {
        switch self {
        case .wavy: "Wavy"
        case .counter: "Counter"
        }
    }
}
