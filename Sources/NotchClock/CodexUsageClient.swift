import AppKit

/// A short-lived, bounded app-server session. Codex owns authentication; the host never reads credentials.
@MainActor
final class CodexUsageClient {
    private let executableOverride: URL?
    private let requestTimeout: Duration
    private var process: Process?
    private var input: Pipe?
    private var output: Pipe?
    private var timeout: Task<Void, Never>?
    private var buffer = Data()
    private var generation = UUID()
    private var completion: ((Result<UsageSnapshot, Error>) -> Void)?
    var isRunning: Bool { process != nil }

    init(executableURL: URL? = nil, requestTimeout: Duration = .seconds(12)) {
        self.executableOverride = executableURL
        self.requestTimeout = requestTimeout
    }

    func fetch(completion: @escaping (Result<UsageSnapshot, Error>) -> Void) {
        guard process == nil else { return }
        let candidates = executableOverride.map { [$0.path] } ?? ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"]
        guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            completion(.failure(UsageError.invalid("Codex CLI not found in /opt/homebrew/bin or /usr/local/bin.")))
            return
        }
        self.completion = completion
        generation = UUID()
        let token = generation
        let task = Process()
        let input = Pipe(), output = Pipe()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = ["app-server"]
        task.standardInput = input
        task.standardOutput = output
        task.standardError = FileHandle.nullDevice
        task.environment = ProcessInfo.processInfo.environment.merging(["PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"]) { _, new in new }
        self.process = task
        self.input = input
        self.output = output
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            Task { @MainActor [weak self] in
                guard let self, self.generation == token, self.process != nil else { return }
                if data.isEmpty { self.finish(.failure(UsageError.invalid("Codex closed the usage connection."))); return }
                self.receive(data)
            }
        }
        task.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token, self.process != nil else { return }
                self.finish(.failure(UsageError.invalid("Codex usage service exited before responding.")))
            }
        }
        do {
            try task.run()
            try send(["id": 1, "method": "initialize", "params": ["clientInfo": ["name": "wavy_clock", "version": "0.1.0"], "capabilities": ["experimentalApi": true]]])
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: self?.requestTimeout ?? .seconds(12)) } catch { return }
                self?.finish(.failure(UsageError.invalid("Codex usage request timed out. Try again when connected.")))
            }
        } catch { finish(.failure(error)) }
    }

    func cancel() {
        generation = UUID()
        timeout?.cancel()
        timeout = nil
        output?.fileHandleForReading.readabilityHandler = nil
        process?.terminationHandler = nil
        if process?.isRunning == true { process?.terminate() }
        try? input?.fileHandleForWriting.close()
        input = nil
        output = nil
        process = nil
        buffer.removeAll(keepingCapacity: false)
        completion = nil
    }

    private func send(_ object: [String: Any]) throws {
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(10)
        try input?.fileHandleForWriting.write(contentsOf: data)
    }

    private func receive(_ data: Data) {
        buffer.append(data)
        guard buffer.count <= 262_144 else { finish(.failure(UsageError.invalid("Codex response exceeded the size limit."))); return }
        do {
            while let end = buffer.firstIndex(of: 10) {
                let line = Data(buffer[..<end])
                buffer.removeSubrange(...end)
                guard !line.isEmpty else { continue }
                guard let message = try JSONSerialization.jsonObject(with: line) as? [String: Any] else { continue }
                if let error = message["error"] as? [String: Any] {
                    let text = String((error["message"] as? String ?? "Codex could not read usage.").prefix(200))
                    throw UsageError.invalid(text)
                }
                if message["id"] as? Int == 1 {
                    try send(["method": "initialized"])
                    try send(["id": 2, "method": "account/rateLimits/read"])
                } else if message["id"] as? Int == 2, let result = message["result"] as? [String: Any] {
                    let snapshot = try UsageSnapshot.codex(result: JSONSerialization.data(withJSONObject: result))
                    finish(.success(snapshot))
                    return
                }
            }
        } catch { finish(.failure(error)) }
    }

    private func finish(_ result: Result<UsageSnapshot, Error>) {
        let callback = completion
        cancel()
        callback?(result)
    }
}
