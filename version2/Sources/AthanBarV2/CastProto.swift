import Foundation

/// Minimal protobuf coder for Google Cast's CastMessage (cast_channel.proto).
enum CastProto {
    static func encode(
        sourceId: String,
        destinationId: String,
        namespace: String,
        json: String
    ) -> Data {
        var body = Data()
        body.appendVarintField(1, value: 0) // protocol_version = CASTV2_1_0
        body.appendStringField(2, value: sourceId)
        body.appendStringField(3, value: destinationId)
        body.appendStringField(4, value: namespace)
        body.appendVarintField(5, value: 0) // payload_type = STRING
        body.appendStringField(6, value: json)

        var packet = Data()
        packet.appendUInt32BE(UInt32(body.count))
        packet.append(body)
        return packet
    }

    static func decode(_ body: Data) -> CastPacket? {
        var reader = ProtoReader(data: body)
        var sourceId = ""
        var destinationId = ""
        var namespace = ""
        var payload = ""

        while let (field, wire) = reader.nextField() {
            switch (field, wire) {
            case (1, 0):
                _ = reader.readVarint()
            case (2, 2):
                sourceId = reader.readString() ?? ""
            case (3, 2):
                destinationId = reader.readString() ?? ""
            case (4, 2):
                namespace = reader.readString() ?? ""
            case (5, 0):
                _ = reader.readVarint()
            case (6, 2):
                payload = reader.readString() ?? ""
            default:
                reader.skip(wire: wire)
            }
        }

        guard !namespace.isEmpty else { return nil }
        return CastPacket(
            sourceId: sourceId,
            destinationId: destinationId,
            namespace: namespace,
            json: payload
        )
    }
}

struct CastPacket {
    let sourceId: String
    let destinationId: String
    let namespace: String
    let json: String

    var object: [String: Any] {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return obj
    }

    var type: String {
        object["type"] as? String ?? ""
    }
}

private struct ProtoReader {
    let data: Data
    var offset = 0

    mutating func nextField() -> (field: UInt64, wire: UInt64)? {
        guard let tag = readVarint() else { return nil }
        return (tag >> 3, tag & 7)
    }

    mutating func readVarint() -> UInt64? {
        var result: UInt64 = 0
        var shift = 0
        while offset < data.count {
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift > 63 { return nil }
        }
        return nil
    }

    mutating func readString() -> String? {
        guard let bytes = readLengthData() else { return nil }
        return String(data: bytes, encoding: .utf8)
    }

    mutating func readLengthData() -> Data? {
        guard let length = readVarint() else { return nil }
        let end = offset + Int(length)
        guard end <= data.count else { return nil }
        let slice = data.subdata(in: offset..<end)
        offset = end
        return slice
    }

    mutating func skip(wire: UInt64) {
        switch wire {
        case 0:
            _ = readVarint()
        case 1:
            offset += 8
        case 2:
            _ = readLengthData()
        case 5:
            offset += 4
        default:
            offset = data.count
        }
    }
}

private extension Data {
    mutating func appendVarint(_ value: UInt64) {
        var current = value
        while current > 0x7F {
            append(UInt8((current & 0x7F) | 0x80))
            current >>= 7
        }
        append(UInt8(current))
    }

    mutating func appendVarintField(_ field: UInt64, value: UInt64) {
        appendVarint((field << 3) | 0)
        appendVarint(value)
    }

    mutating func appendStringField(_ field: UInt64, value: String) {
        let bytes = Data(value.utf8)
        appendVarint((field << 3) | 2)
        appendVarint(UInt64(bytes.count))
        append(bytes)
    }

    mutating func appendUInt32BE(_ value: UInt32) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { append(contentsOf: $0) }
    }
}
