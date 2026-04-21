import Foundation
import os.log

private let logger = Logger(subsystem: "com.clippable.clipboard", category: "RemoteManager")

class RemoteManager {
    static let shared = RemoteManager()

    struct RemoteConnection: Identifiable, Hashable {
        let id = UUID()
        let host: String
        let displayName: String
    }

    private init() {}

    /// Detect active VSCode SSH remote connections
    func detectVSCodeConnections() -> [RemoteConnection] {
        // Only match actual ssh processes (not VSCode Helper that contains sshArgs in JSON)
        guard let output = shell("/bin/sh", ["-c", "ps -eo command | grep '^ssh.*-T.*-D' | grep -v grep"]) else {
            return []
        }

        var connections: [RemoteConnection] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines where !line.isEmpty {
            // Parse: ssh -v -T -D <port> -o ... <host>
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if let host = parts.last, !host.isEmpty, !host.starts(with: "-") {
                let conn = RemoteConnection(host: host, displayName: host)
                if !connections.contains(where: { $0.host == host }) {
                    connections.append(conn)
                }
            }
        }

        debugLog("detectVSCodeConnections: found \(connections.count) -> \(connections.map(\.host))")
        return connections
    }

    /// Send files to remote host via scp
    func sendFiles(localPaths: [String], to host: String, remotePath: String = "/tmp/clippable/", completion: @escaping (Bool, String) -> Void) {
        debugLog("sendFiles: \(localPaths) -> \(host):\(remotePath)")

        // Check local files exist
        for path in localPaths {
            if !FileManager.default.fileExists(atPath: path) {
                completion(false, "File not found: \(path)")
                return
            }
        }

        // mkdir on remote
        let mkdirResult = shell("/usr/bin/ssh", ["-o", "ConnectTimeout=5", host, "mkdir", "-p", remotePath])
        if mkdirResult == nil {
            completion(false, "SSH mkdir failed")
            return
        }
        debugLog("mkdir OK")

        // scp
        let args = ["-o", "ConnectTimeout=5"] + localPaths + ["\(host):\(remotePath)"]
        let scpResult = shell("/usr/bin/scp", args)

        let fileNames = localPaths.map { ($0 as NSString).lastPathComponent }
        let resultPaths = fileNames.map { remotePath + $0 }.joined(separator: ", ")

        if scpResult != nil {
            debugLog("SCP success: \(resultPaths)")
            completion(true, resultPaths)
        } else {
            debugLog("SCP failed")
            completion(false, "SCP failed")
        }
    }

    /// Run a command and return stdout, or nil on failure. Avoids Pipe deadlock.
    private func shell(_ executable: String, _ arguments: [String]) -> String? {
        let outFile = "/tmp/clippable_cmd_\(UUID().uuidString).tmp"
        defer { try? FileManager.default.removeItem(atPath: outFile) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle(forWritingAtPath: {
            FileManager.default.createFile(atPath: outFile, contents: nil)
            return outFile
        }())
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }
        return try? String(contentsOfFile: outFile, encoding: .utf8)
    }
}
