import AppKit

if CommandLine.arguments.contains("--capture-claude-usage") {
    // Claude sends session metadata on stdin. Persist only the normalized quota snapshot.
    do {
        var input = Data()
        while let chunk = try FileHandle.standardInput.read(upToCount: 65_536), !chunk.isEmpty {
            input.append(chunk)
            guard input.count <= 1_048_576 else { throw UsageError.invalid("Status-line input exceeds 1 MiB.") }
        }
        let snapshot = try UsageSnapshot.claude(statusLine: input)
        let args = CommandLine.arguments
        let cache: UsageCache
        if let index = args.firstIndex(of: "--usage-cache-directory"), args.indices.contains(index + 1) {
            cache = UsageCache(directory: URL(fileURLWithPath: args[index + 1], isDirectory: true))
        } else { cache = .standard }
        try cache.save(snapshot)
        let summary = snapshot.windows.map { "\($0.shortLabel) \(Int($0.usedPercent))% used" }.joined(separator: " · ")
        print(summary.isEmpty ? "Claude usage unavailable" : "Claude " + summary)
    } catch {
        FileHandle.standardError.write(Data("Wavy Clock could not capture Claude usage.\n".utf8))
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
