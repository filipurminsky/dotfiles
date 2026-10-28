// micstatus — report whether anything is currently capturing from the mic.
//
// Usage:
//   micstatus            print "on" or "off" and exit
//   micstatus --watch    stay resident and fire sketchybar's mic_change event
//                        whenever that answer flips
//
// Why this and not something simpler: macOS has no public API for "who is
// recording", and the orange dot itself is drawn by the window server from
// TCC state that nothing outside the system can read. What *is* readable is
// CoreAudio's kAudioDevicePropertyDeviceIsRunningSomewhere — true while any
// process in the system has an IOProc running on the device. Asking that of
// every device with input channels tracks the dot closely, needs no
// microphone TCC grant (we never open a stream, only read a property), and
// costs nothing while idle. ioreg is not an option: the IOAudioEngine nodes
// its state used to live in do not exist on Apple Silicon.
//
// The property is documented as global-scope, so on a combo device (USB
// headset, AirPods) a plain read cannot tell capture from playback, and
// sound coming *out* would light the item up. Drivers that do honour a scope
// answer an input-scoped read; those that don't return an error, and only
// then do we fall back to the global answer.
//
// Build (bootstrap.sh does this; the repo tracks this source, not the binary):
//
//   swiftc -O micstatus.swift -o micstatus

import CoreAudio
import Foundation

let system = AudioObjectID(kAudioObjectSystemObject)

func address(_ selector: AudioObjectPropertySelector,
             _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal)
    -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector,
                               mScope: scope,
                               mElement: kAudioObjectPropertyElementMain)
}

/// Every audio device that has at least one input channel.
func inputDevices() -> [AudioDeviceID] {
    var listAddr = address(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &listAddr, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(system, &listAddr, 0, nil, &size, &ids) == noErr else { return [] }

    return ids.filter { id in
        var cfgAddr = address(kAudioDevicePropertyStreamConfiguration, kAudioDevicePropertyScopeInput)
        var cfgSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &cfgAddr, 0, nil, &cfgSize) == noErr, cfgSize > 0
        else { return false }
        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(cfgSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { buffer.deallocate() }
        guard AudioObjectGetPropertyData(id, &cfgAddr, 0, nil, &cfgSize, buffer) == noErr
        else { return false }
        let list = UnsafeMutableAudioBufferListPointer(
            buffer.assumingMemoryBound(to: AudioBufferList.self))
        return list.contains { $0.mNumberChannels > 0 }
    }
}

func isCapturing(_ id: AudioDeviceID) -> Bool {
    for scope in [kAudioDevicePropertyScopeInput, kAudioObjectPropertyScopeGlobal] {
        var addr = address(kAudioDevicePropertyDeviceIsRunningSomewhere, scope)
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &running) == noErr {
            return running != 0
        }
    }
    return false
}

func micIsLive() -> Bool { inputDevices().contains(where: isCapturing) }

guard CommandLine.arguments.contains("--watch") else {
    print(micIsLive() ? "on" : "off")
    exit(0)
}

// ---- watch mode ----------------------------------------------------------
// One resident process with CoreAudio listeners beats polling the bar every
// couple of seconds: the item flips the instant recording starts or stops,
// and nothing runs in between. The item keeps a slow update_freq anyway as a
// safety net in case this process dies.

let sketchybar = ["/opt/homebrew/bin/sketchybar", "/usr/local/bin/sketchybar"]
    .first { FileManager.default.isExecutableFile(atPath: $0) }

let queue = DispatchQueue(label: "micstatus.watch")
var watched: Set<AudioDeviceID> = []
var lastState: Bool?

func publish() {
    let state = micIsLive()
    guard state != lastState else { return }
    lastState = state
    guard let sketchybar else { return }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: sketchybar)
    task.arguments = ["--trigger", "mic_change"]
    try? task.run()
    task.waitUntilExit()   // reap it; this queue is ours to block
}

// Stored, not inline: AudioObjectRemovePropertyListenerBlock only unregisters
// a block it can match against the one that was added.
let runningListener: AudioObjectPropertyListenerBlock = { _, _ in publish() }

/// Follow the current set of input devices — plugging in a headset mid-call
/// has to start a listener, unplugging it has to stop one.
func syncListeners() {
    let current = Set(inputDevices())
    var addr = address(kAudioDevicePropertyDeviceIsRunningSomewhere, kAudioDevicePropertyScopeInput)
    for device in current.subtracting(watched) {
        AudioObjectAddPropertyListenerBlock(device, &addr, queue, runningListener)
    }
    for device in watched.subtracting(current) {
        AudioObjectRemovePropertyListenerBlock(device, &addr, queue, runningListener)
    }
    watched = current
}

let deviceListListener: AudioObjectPropertyListenerBlock = { _, _ in
    syncListeners()
    publish()
}
var deviceListAddr = address(kAudioHardwarePropertyDevices)
AudioObjectAddPropertyListenerBlock(system, &deviceListAddr, queue, deviceListListener)

queue.async {
    syncListeners()
    publish()   // lastState is nil, so this always paints the initial state
}

dispatchMain()
