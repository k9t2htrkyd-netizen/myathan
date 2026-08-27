import Foundation

struct CastDevice: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let model: String
    let host: String
    let port: Int

    var label: String {
        model.isEmpty ? "\(name) · \(host)" : "\(name) · \(model)"
    }
}

enum CastError: LocalizedError {
    case invalidHost
    case connectFailed(String)
    case timeout
    case launchFailed(String)
    case loadFailed(String)
    case notConnected
    case noLocalAddress
    case missingAudioFile

    var errorDescription: String? {
        switch self {
        case .invalidHost: return "Enter a valid IP address."
        case .connectFailed(let message): return "Could not connect: \(message)"
        case .timeout: return "The speaker did not respond in time."
        case .launchFailed(let message): return "Could not start the Cast player: \(message)"
        case .loadFailed(let message): return "Could not start audio on the speaker: \(message)"
        case .notConnected: return "Not connected to a Cast speaker."
        case .noLocalAddress: return "This Mac has no Wi-Fi/LAN address the speaker can reach."
        case .missingAudioFile: return "Adhan audio file is missing."
        }
    }
}
