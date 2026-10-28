// Report active input streams using CoreAudio process objects (macOS 14.2+).
// This distinguishes recording from playback on duplex devices. It reads
// metadata only; no audio stream is opened and no microphone grant is needed.
// Build: swiftc -O micstatus.swift -o micstatus
import CoreAudio
import Foundation

let system = AudioObjectID(kAudioObjectSystemObject)
func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                               mElement: kAudioObjectPropertyElementMain)
}

func processes() -> [AudioObjectID]? {
    var addr = address(kAudioHardwarePropertyProcessObjectList)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return nil }
    if size == 0 { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &ids) == noErr else { return nil }
    return ids
}

func state() -> String {
    guard let ids = processes() else { return "unknown" }
    var failed = false
    for id in ids {
        var addr = address(kAudioProcessPropertyIsRunningInput)
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &running) == noErr {
            if running != 0 { return "on" }
        } else { failed = true }
    }
    return failed ? "unknown" : "off"
}

guard CommandLine.arguments.contains("--watch") else {
    print(state())
    exit(0)
}

let sketchybar = ["/opt/homebrew/bin/sketchybar", "/usr/local/bin/sketchybar"]
    .first { FileManager.default.isExecutableFile(atPath: $0) }
let queue = DispatchQueue(label: "micstatus.watch")
var watched: Set<AudioObjectID> = []
var lastState: String?
func publish() {
    let current = state()
    guard current != lastState, let sketchybar else { return }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: sketchybar)
    task.arguments = ["--trigger", "mic_change"]
    do {
        try task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 { lastState = current }
    } catch { /* retry on the next event or recovery timer */ }
}
let runningListener: AudioObjectPropertyListenerBlock = { _, _ in publish() }
func syncListeners() {
    guard let ids = processes() else { return }
    let current = Set(ids)
    var addr = address(kAudioProcessPropertyIsRunningInput)
    for id in watched.subtracting(current) {
        AudioObjectRemovePropertyListenerBlock(id, &addr, queue, runningListener)
        watched.remove(id)
    }
    for id in current.subtracting(watched) {
        if AudioObjectAddPropertyListenerBlock(id, &addr, queue, runningListener) == noErr {
            watched.insert(id)
        }
    }
}
let processListListener: AudioObjectPropertyListenerBlock = { _, _ in
    syncListeners()
    publish()
}
var listAddr = address(kAudioHardwarePropertyProcessObjectList)
let hasListListener = AudioObjectAddPropertyListenerBlock(system, &listAddr, queue, processListListener) == noErr
// Recover failed registrations and service restarts; publication still only
// spawns SketchyBar when the state changes or a previous trigger failed.
let recovery = DispatchSource.makeTimerSource(queue: queue)
recovery.schedule(deadline: .now(), repeating: hasListListener ? 30 : 5)
recovery.setEventHandler { syncListeners(); publish() }
recovery.resume()
dispatchMain()
