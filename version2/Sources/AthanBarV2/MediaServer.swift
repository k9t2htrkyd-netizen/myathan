import Darwin
import Foundation
import Network

/// Serves local Adhan MP3 files over HTTP so a Nest / Chromecast can fetch them.
final class MediaServer {
    static let shared = MediaServer()

    private let queue = DispatchQueue(label: "athan.v2.media-server")
    private var listener: NWListener?
    private var files: [String: URL] = [:]
    private(set) var port: UInt16 = 18765
    private(set) var isRunning = false

    var lanIPv4: String? {
        LocalIPv4.bestAddress()
    }

    func start() throws {
        if isRunning { return }
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.acceptLocalOnly = false
        parameters.includePeerToPeer = true
        let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .global())
            self?.handle(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        files.removeAll()
    }

    /// Publishes a local file and returns a LAN URL the speaker can download.
    func publish(_ fileURL: URL, preferredIP: String? = nil) throws -> URL {
        try start()
        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        queue.sync { files[String(token)] = fileURL }
        let host = preferredIP ?? lanIPv4
        guard let host else {
            throw CastError.noLocalAddress
        }
        guard let url = URL(string: "http://\(host):\(port)/m/\(token).mp3") else {
            throw CastError.noLocalAddress
        }
        return url
    }

    private func handle(_ connection: NWConnection) {
        receiveHeader(connection, buffer: Data())
    }

    private func receiveHeader(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let error {
                connection.cancel()
                print("Media server receive error: \(error)")
                return
            }
            var next = buffer
            if let data { next.append(data) }
            if let range = next.range(of: Data("\r\n\r\n".utf8)) {
                let header = next.subdata(in: next.startIndex..<range.lowerBound)
                self.respond(connection, header: header)
                return
            }
            if isComplete || next.count > 32_768 {
                connection.cancel()
                return
            }
            self.receiveHeader(connection, buffer: next)
        }
    }

    private func respond(_ connection: NWConnection, header: Data) {
        let text = String(data: header, encoding: .utf8) ?? ""
        let lines = text.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let requestLine = lines.first ?? ""
        let parts = requestLine.split(separator: " ")
        let method = parts.first.map(String.init) ?? "GET"
        let path = parts.count > 1 ? String(parts[1]) : "/"
        let pathOnly = String(path.split(separator: "?").first ?? Substring(path))

        let rangeHeader = lines.first(where: { $0.lowercased().hasPrefix("range:") })

        guard pathOnly.hasPrefix("/m/"),
              let token = pathOnly.split(separator: "/").last?.replacingOccurrences(of: ".mp3", with: ""),
              let fileURL = queue.sync(execute: { files[token] }),
              let fileData = try? Data(contentsOf: fileURL)
        else {
            send(connection, status: "HTTP/1.1 404 Not Found", headers: ["Content-Length": "0"], body: Data())
            return
        }

        let total = fileData.count
        var start = 0
        var end = total - 1
        var status = "HTTP/1.1 200 OK"

        if let rangeHeader {
            let value = rangeHeader.split(separator: ":", maxSplits: 1).last.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? ""
            if value.lowercased().hasPrefix("bytes=") {
                let spec = String(value.dropFirst(6))
                let bounds = spec.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
                if let first = bounds.first, let parsed = Int(first), !first.isEmpty {
                    start = parsed
                }
                if bounds.count > 1, let parsed = Int(bounds[1]) {
                    end = parsed
                }
                start = max(0, min(start, total - 1))
                end = max(start, min(end, total - 1))
                status = "HTTP/1.1 206 Partial Content"
            }
        }

        let slice = fileData.subdata(in: start..<(end + 1))
        var headers = [
            "Content-Type": "audio/mpeg",
            "Accept-Ranges": "bytes",
            "Content-Length": "\(slice.count)",
            "Connection": "close",
            "Access-Control-Allow-Origin": "*",
        ]
        if status.contains("206") {
            headers["Content-Range"] = "bytes \(start)-\(end)/\(total)"
        }

        if method == "HEAD" {
            send(connection, status: status, headers: headers, body: Data())
        } else {
            send(connection, status: status, headers: headers, body: slice)
        }
    }

    private func send(_ connection: NWConnection, status: String, headers: [String: String], body: Data) {
        var message = status + "\r\n"
        for (key, value) in headers {
            message += "\(key): \(value)\r\n"
        }
        message += "\r\n"
        var payload = Data(message.utf8)
        payload.append(body)
        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

enum LocalIPv4 {
    static func addresses() -> [String] {
        var result: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(first) }

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let flags = Int32(interface.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }
            let name = String(cString: interface.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("bridge") || name.hasPrefix("wlan") else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let addrLen = socklen_t(interface.ifa_addr.pointee.sa_len)
            getnameinfo(interface.ifa_addr, addrLen, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            let ip = String(cString: host)
            if !ip.hasPrefix("127.") {
                result.append(ip)
            }
        }
        return result
    }

    static func bestAddress(matchingDeviceIP deviceIP: String? = nil) -> String? {
        let all = addresses()
        if let deviceIP {
            let prefix = deviceIP.split(separator: ".").prefix(3).joined(separator: ".")
            if let match = all.first(where: { $0.hasPrefix(prefix) }) {
                return match
            }
        }
        return all.first
    }
}
