import Foundation

enum ClockRenderer: String, Codable, Sendable { case wavyAnalog, capsuleDigital }

struct ClockDesign: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let renderer: ClockRenderer
    let accent: String
}

struct ClockPack: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let id: String
    let name: String
    let clocks: [ClockDesign]
    let widgets: [WidgetDesign]?
    var themes: [ThemeDesign]? = nil

    static let builtIn = ClockPack(schemaVersion: 1, id: "dev.kavrin.originals", name: "Originals", clocks: [
        ClockDesign(id: "wavy", name: "The Wavy One", renderer: .wavyAnalog, accent: "C93D33"),
        ClockDesign(id: "digital", name: "The Digital One", renderer: .capsuleDigital, accent: "C93D33")
    ], widgets: WidgetDesign.originals, themes: ThemeDesign.originals)

    static func decode(_ data: Data) throws -> ClockPack {
        guard data.count <= 65_536 else { throw ClockPackError.invalid("Manifest exceeds 64 KiB.") }
        let pack = try JSONDecoder().decode(ClockPack.self, from: data)
        func validID(_ value: String) -> Bool {
            !value.isEmpty && value.count <= 80 && value.range(of: "^[a-z0-9][a-z0-9.-]*$", options: .regularExpression) != nil
        }
        guard pack.schemaVersion == 1, validID(pack.id), pack.id != builtIn.id,
              !pack.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, pack.name.count <= 60,
              (0...24).contains(pack.clocks.count), Set(pack.clocks.map(\.id)).count == pack.clocks.count,
              pack.clocks.count + (pack.widgets?.count ?? 0) + (pack.themes?.count ?? 0) > 0, (pack.widgets?.count ?? 0) <= 24,
              Set((pack.widgets ?? []).map(\.id)).count == (pack.widgets?.count ?? 0),
              (pack.themes?.count ?? 0) <= 24,
              Set((pack.themes ?? []).map(\.id)).count == (pack.themes?.count ?? 0) else {
            throw ClockPackError.invalid("Unsupported schema, reserved or invalid pack ID, name, or clock list.")
        }
        for clock in pack.clocks {
            guard validID(clock.id), !clock.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  clock.name.count <= 60, clock.accent.range(of: "^[A-Fa-f0-9]{6}$", options: .regularExpression) != nil else {
                throw ClockPackError.invalid("Each clock needs a unique ID, a name, and a six-digit RGB accent.")
            }
        }
        for widget in pack.widgets ?? [] {
            guard validID(widget.id), !widget.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  widget.name.count <= 60, widget.accent.range(of: "^[A-Fa-f0-9]{6}$", options: .regularExpression) != nil else {
                throw ClockPackError.invalid("Each widget needs a unique ID, a name, and a six-digit RGB accent.")
            }
        }
        for theme in pack.themes ?? [] {
            guard validID(theme.id), !theme.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  theme.name.count <= 60, theme.hasValidColors else {
                throw ClockPackError.invalid("Each theme needs a unique ID, a name, and seven six-digit RGB colors.")
            }
        }
        return pack
    }
}

enum ClockPackError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

/// Stores only validated JSON. Imported folders, scripts, and assets never enter the app's runtime.
struct ClockPackStore {
    let directory: URL

    func installed() -> (packs: [ClockPack], warnings: [String]) {
        guard FileManager.default.fileExists(atPath: directory.path) else { return ([], []) }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var packs: [ClockPack] = []
            var warnings: [String] = []
            for file in files.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                do {
                    let pack = try read(file)
                    guard file.lastPathComponent == pack.id + ".json", !packs.contains(where: { $0.id == pack.id }) else {
                        throw ClockPackError.invalid("Pack filename and ID do not match.")
                    }
                    packs.append(pack)
                } catch { warnings.append("\(file.lastPathComponent): \(error.localizedDescription)") }
            }
            return (packs, warnings)
        } catch { return ([], [error.localizedDescription]) }
    }

    func install(manifest: URL) throws -> ClockPack {
        let pack = try read(manifest)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(pack.id + ".json")
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            throw ClockPackError.invalid("This pack is already installed. Remove its installed JSON before replacing it.")
        }
        // Atomic writes keep interrupted installation from leaving a partially decoded pack at next launch.
        try JSONEncoder().encode(pack).write(to: destination, options: .atomic)
        return pack
    }

    private func read(_ file: URL) throws -> ClockPack {
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true, (values.fileSize ?? Int.max) <= 65_536 else {
            throw ClockPackError.invalid("Choose a regular JSON manifest of at most 64 KiB.")
        }
        return try ClockPack.decode(Data(contentsOf: file))
    }
}
