import Foundation
import Network
import Security

/// Google Cast v2 client. Sends audio to Nest Mini / Nest Audio / Chromecast.
final class CastClient {
    static let mediaReceiverAppID = "CC1AD845"
    static let connectionNS = "urn:x-cast:com.google.cast.tp.connection"
    static let heartbeatNS = "urn:x-cast:com.google.cast.tp.heartbeat"
    static let receiverNS = "urn:x-cast:com.google.cast.receiver"
    static let mediaNS = "urn:x-cast:com.google.cast.media"

    private let queue = DispatchQueue(label: "athan.v2.cast")
    private var connection: NWConnection?
    private var buffer = Data()
    private var requestId = 1
    private var heartbeat: DispatchSourceTimer?
    private var transportId: String?
    private var mediaSessionId: Int?
    private var lastApps: [[String: Any]] = []
    private var lastPlayerState: String = ""
    private var connected = false
    private var connectContinuation: CheckedContinuation<Void, Error>?

    var onPlayerState: ((String) -> Void)?
    var onDisconnected: ((String) -> Void)?

    var isConnected: Bool { connected }

    func connect(host: String, port: UInt16 = 8009) async throws {
        await disconnect()
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CastError.invalidHost
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                self.connectContinuation = continuation
                let tls = NWProtocolTLS.Options()
                sec_protocol_options_set_min_tls_protocol_version(
                    tls.securityProtocolOptions,
                    .TLSv12
                )
                sec_protocol_options_set_verify_block(
                    tls.securityProtocolOptions,
                    { _, _, complete in complete(true) },
                    self.queue
                )

                let parameters = NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
                parameters.includePeerToPeer = true
                let connection = NWConnection(
                    host: NWEndpoint.Host(host),
                    port: NWEndpoint.Port(rawValue: port) ?? 8009,
                    using: parameters
                )
                self.connection = connection

                connection.stateUpdateHandler = { [weak self] state in
                    guard let self, self.connection === connection else { return }
                    switch state {
                    case .ready:
                        self.connected = true
                        self.startReceive()
                        self.sendConnect(to: "receiver-0")
                        self.sendJSON(namespace: Self.receiverNS, destination: "receiver-0", [
                            "type": "GET_STATUS",
                            "requestId": self.nextRequestId(),
                        ])
                        self.startHeartbeat()
                        self.finishConnect(Result.success(()))
                    case .failed(let error):
                        self.connected = false
                        self.finishConnect(Result.failure(CastError.connectFailed(error.localizedDescription)))
                    case .waiting(let error):
                        if Self.isFatal(error) {
                            self.connected = false
                            self.finishConnect(Result.failure(CastError.connectFailed(error.localizedDescription)))
                        }
                    case .cancelled:
                        self.connected = false
                        self.finishConnect(Result.failure(CastError.connectFailed("Connection cancelled.")))
                    default:
                        break
                    }
                }
                connection.start(queue: self.queue)
            }
        }
    }

    private func finishConnect(_ result: Result<Void, Error>) {
        guard let continuation = connectContinuation else { return }
        connectContinuation = nil
        continuation.resume(with: result)
    }

    func play(mediaURL: URL, contentType: String = "audio/mpeg") async throws {
        guard connected else { throw CastError.notConnected }
        lastPlayerState = ""
        mediaSessionId = nil
        try await launchMediaReceiver()
        guard let transportId else { throw CastError.launchFailed("No media session on the speaker.") }
        sendConnect(to: transportId)
        try await Task.sleep(nanoseconds: 250_000_000)

        sendJSON(namespace: Self.mediaNS, destination: transportId, [
            "type": "LOAD",
            "requestId": nextRequestId(),
            "media": [
                "contentId": mediaURL.absoluteString,
                "streamType": "BUFFERED",
                "contentType": contentType,
            ],
            "autoplay": true,
            "currentTime": 0,
        ])

        do {
            try await waitUntil(timeout: 6) {
                ["BUFFERING", "PLAYING"].contains(self.lastPlayerState)
            }
        } catch {
            lastPlayerState = "PLAYING"
        }
    }

    func setVolume(_ level: Float) {
        guard connected else { return }
        sendJSON(namespace: Self.receiverNS, destination: "receiver-0", [
            "type": "SET_VOLUME",
            "requestId": nextRequestId(),
            "volume": [
                "level": Double(min(max(level, 0), 1)),
                "muted": false,
            ],
        ])
    }

    func stopPlayback() {
        guard connected else { return }
        if let transportId, let mediaSessionId {
            sendJSON(namespace: Self.mediaNS, destination: transportId, [
                "type": "STOP",
                "requestId": nextRequestId(),
                "mediaSessionId": mediaSessionId,
            ])
        }
        sendJSON(namespace: Self.receiverNS, destination: "receiver-0", [
            "type": "STOP",
            "requestId": nextRequestId(),
        ])
        lastPlayerState = "IDLE"
    }

    func disconnect() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                self.heartbeat?.cancel()
                self.heartbeat = nil
                self.finishConnect(Result.failure(CastError.connectFailed("Connection cancelled.")))
                if self.connected {
                    self.sendJSON(namespace: Self.connectionNS, destination: "receiver-0", ["type": "CLOSE"])
                }
                self.connection?.stateUpdateHandler = nil
                self.connection?.cancel()
                self.connection = nil
                self.connected = false
                self.buffer.removeAll()
                self.transportId = nil
                self.mediaSessionId = nil
                self.lastApps = []
                self.lastPlayerState = ""
                continuation.resume()
            }
        }
    }

    private func launchMediaReceiver() async throws {
        sendJSON(namespace: Self.receiverNS, destination: "receiver-0", [
            "type": "GET_STATUS",
            "requestId": nextRequestId(),
        ])
        try await Task.sleep(nanoseconds: 400_000_000)

        if mediaApp() == nil {
            sendJSON(namespace: Self.receiverNS, destination: "receiver-0", [
                "type": "LAUNCH",
                "appId": Self.mediaReceiverAppID,
                "requestId": nextRequestId(),
            ])
        }

        try await waitUntil(timeout: 10) { self.mediaApp() != nil }
        if let app = mediaApp() {
            transportId = app["transportId"] as? String
        }
        if transportId == nil {
            throw CastError.launchFailed("Speaker did not open the media player.")
        }
    }

    private func mediaApp() -> [String: Any]? {
        lastApps.first { app in
            (app["appId"] as? String) == Self.mediaReceiverAppID
                || ((app["namespaces"] as? [[String: Any]])?.contains(where: {
                    ($0["name"] as? String) == Self.mediaNS
                }) ?? false)
        }
    }

    private func waitUntil(timeout: TimeInterval, predicate: @escaping () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if queue.sync(execute: predicate) { return }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw CastError.timeout
    }

    private func sendConnect(to destination: String) {
        sendJSON(namespace: Self.connectionNS, destination: destination, [
            "type": "CONNECT",
            "origin": [:] as [String: Any],
            "userAgent": "AthanBarV2",
        ])
    }

    private func startHeartbeat() {
        heartbeat?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 5, repeating: 5)
        timer.setEventHandler { [weak self] in
            self?.sendJSON(namespace: Self.heartbeatNS, destination: "receiver-0", ["type": "PING"])
        }
        timer.resume()
        heartbeat = timer
    }

    private func startReceive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.buffer.append(data)
                self.drain()
            }
            if let error {
                self.connected = false
                DispatchQueue.main.async {
                    self.onDisconnected?(error.localizedDescription)
                }
                return
            }
            if isComplete {
                self.connected = false
                DispatchQueue.main.async {
                    self.onDisconnected?("Speaker closed the connection.")
                }
                return
            }
            self.startReceive()
        }
    }

    private func drain() {
        while buffer.count >= 4 {
            let length = UInt32(buffer[0]) << 24
                | UInt32(buffer[1]) << 16
                | UInt32(buffer[2]) << 8
                | UInt32(buffer[3])
            if length == 0 || length > 1_000_000 { return }
            let total = 4 + Int(length)
            guard buffer.count >= total else { return }
            let body = buffer.subdata(in: 4..<total)
            buffer.removeSubrange(0..<total)
            handle(body)
        }
    }

    private func handle(_ body: Data) {
        guard let packet = CastProto.decode(body) else { return }
        if packet.type == "PING" {
            sendJSON(namespace: packet.namespace, destination: packet.sourceId, ["type": "PONG"])
            return
        }
        if packet.type == "CLOSE" {
            connected = false
            DispatchQueue.main.async { self.onDisconnected?("Speaker ended the Cast session.") }
            return
        }

        let object = packet.object
        if packet.namespace == Self.receiverNS {
            if let status = object["status"] as? [String: Any] {
                lastApps = status["applications"] as? [[String: Any]] ?? []
                if let app = mediaApp() {
                    transportId = app["transportId"] as? String
                }
            }
            if object["type"] as? String == "LAUNCH_ERROR" {
                let reason = object["reason"] as? String ?? "launch error"
                print("Cast launch error: \(reason)")
            }
        }

        if packet.namespace == Self.mediaNS, let statusList = object["status"] as? [[String: Any]] {
            if let first = statusList.first {
                if let session = first["mediaSessionId"] as? Int {
                    mediaSessionId = session
                }
                if let state = first["playerState"] as? String {
                    lastPlayerState = state
                    DispatchQueue.main.async { self.onPlayerState?(state) }
                }
            }
        }
    }

    private func sendJSON(namespace: String, destination: String, _ payload: [String: Any]) {
        guard let connection, connected || namespace == Self.connectionNS else { return }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8)
        else { return }

        let packet = CastProto.encode(
            sourceId: "sender-athan",
            destinationId: destination,
            namespace: namespace,
            json: json
        )
        connection.send(content: packet, completion: .contentProcessed { _ in })
    }

    private func nextRequestId() -> Int {
        requestId += 1
        return requestId
    }

    private static func isFatal(_ error: NWError) -> Bool {
        switch error {
        case .dns, .tls:
            return true
        default:
            return false
        }
    }
}
