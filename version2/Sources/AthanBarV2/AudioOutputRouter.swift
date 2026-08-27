import CoreAudio
import Foundation

struct SystemAudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let transport: String

    var isBluetooth: Bool {
        transport == "Bluetooth" || transport == "Bluetooth LE"
    }
}

enum AudioOutputRouter {
    static func defaultOutputID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    static func defaultOutputUID() -> String? {
        guard let id = defaultOutputID() else { return nil }
        return uid(of: id)
    }

    static func setDefaultOutput(uid: String) -> Bool {
        guard let device = outputDevices().first(where: { $0.uid == uid }) else { return false }
        return setDefaultOutput(id: device.id)
    }

    static func setDefaultOutput(id: AudioDeviceID) -> Bool {
        var deviceID = id
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        return status == noErr
    }

    static func outputDevices() -> [SystemAudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else {
            return []
        }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids) == noErr else {
            return []
        }

        return ids.compactMap { id in
            guard hasOutput(id), let uid = uid(of: id), let name = name(of: id) else { return nil }
            let transport = transportName(of: id)
            guard !shouldHide(name: name, transport: transport) else { return nil }
            return SystemAudioDevice(
                id: id,
                uid: uid,
                name: name,
                transport: transport
            )
        }
        .sorted { lhs, rhs in
            if lhs.isBluetooth != rhs.isBluetooth { return lhs.isBluetooth && !rhs.isBluetooth }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func hasOutput(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else {
            return false
        }
        let data = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { data.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, data) == noErr else { return false }
        let list = data.assumingMemoryBound(to: AudioBufferList.self).pointee
        return list.mNumberBuffers > 0
    }

    /// AVAudioEngine and apps like Teams create extra virtual devices. Hide those from the picker.
    private static func shouldHide(name: String, transport: String) -> Bool {
        if name.localizedCaseInsensitiveContains("CADefaultDeviceAggregate") { return true }
        if transport == "Virtual" { return true }
        return false
    }

    private static func uid(of id: AudioDeviceID) -> String? {
        cfString(id, kAudioDevicePropertyDeviceUID)
    }

    private static func name(of id: AudioDeviceID) -> String? {
        cfString(id, kAudioObjectPropertyName)
    }

    private static func cfString(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        guard status == noErr, let unmanaged = value else { return nil }
        return unmanaged.takeRetainedValue() as String
    }

    private static func transportName(of id: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &transport) == noErr else {
            return "Unknown"
        }
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn: return "Built-in"
        case kAudioDeviceTransportTypeBluetooth: return "Bluetooth"
        case kAudioDeviceTransportTypeBluetoothLE: return "Bluetooth LE"
        case kAudioDeviceTransportTypeAirPlay: return "AirPlay"
        case kAudioDeviceTransportTypeUSB: return "USB"
        case kAudioDeviceTransportTypeHDMI: return "HDMI"
        case kAudioDeviceTransportTypeDisplayPort: return "DisplayPort"
        case kAudioDeviceTransportTypeAggregate: return "Aggregate"
        case kAudioDeviceTransportTypeVirtual: return "Virtual"
        default: return "Other"
        }
    }
}
