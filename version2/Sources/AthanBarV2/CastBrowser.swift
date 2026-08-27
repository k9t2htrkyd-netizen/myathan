import Darwin
import Foundation

/// Discovers Google Nest / Chromecast speakers on the local network via Bonjour.
final class CastBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var onUpdate: (([CastDevice]) -> Void)?

    private let browser = NetServiceBrowser()
    private var resolving: [NetService] = []
    private var devicesByID: [String: CastDevice] = [:]

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        devicesByID.removeAll()
        onUpdate?([])
        browser.stop()
        browser.searchForServices(ofType: "_googlecast._tcp.", inDomain: "local.")
    }

    func stop() {
        browser.stop()
        resolving.forEach { $0.stop() }
        resolving.removeAll()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        resolving.append(service)
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        devicesByID[service.name] = nil
        publish()
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        defer { resolving.removeAll { $0 === sender } }

        guard let host = ipv4(from: sender) else { return }
        let txt = NetService.dictionary(fromTXTRecord: sender.txtRecordData() ?? Data())
        let name = string(fromTXT: txt, key: "fn") ?? sender.name
        let model = string(fromTXT: txt, key: "md") ?? "Cast speaker"
        let id = string(fromTXT: txt, key: "id") ?? "\(host):\(sender.port)"

        devicesByID[id] = CastDevice(
            id: id,
            name: name,
            model: model,
            host: host,
            port: sender.port == 0 ? 8009 : sender.port
        )
        publish()
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        resolving.removeAll { $0 === sender }
    }

    private func publish() {
        let list = devicesByID.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        DispatchQueue.main.async { self.onUpdate?(list) }
    }

    private func ipv4(from service: NetService) -> String? {
        guard let addresses = service.addresses else { return nil }
        for data in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let ok: Bool = data.withUnsafeBytes { raw in
                guard let addr = raw.bindMemory(to: sockaddr.self).baseAddress else { return false }
                return getnameinfo(
                    addr,
                    socklen_t(data.count),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0
            }
            guard ok else { continue }
            let host = String(cString: hostname)
            if host.contains("."), !host.contains(":") {
                return host
            }
        }
        return nil
    }

    private func string(fromTXT txt: [String: Data], key: String) -> String? {
        guard let data = txt[key], let value = String(data: data, encoding: .utf8), !value.isEmpty else {
            return nil
        }
        return value
    }
}
