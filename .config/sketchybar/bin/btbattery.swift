// btbattery — print the battery percentage of a connected Bluetooth LE device.
//
// Usage: btbattery [name-substring]        (default: "Keychron")
//
// Exit codes, so the caller can tell "keyboard is off" from "read glitched":
//   0  battery percentage printed on stdout
//   2  no connected peripheral matches the name — device is off or unpaired
//   3  Bluetooth is off, or the calling process has no Bluetooth TCC grant
//   1  matched the device but the GATT read failed
//
// Why this and not something simpler: macOS keeps BLE peripheral battery
// levels only inside bluetoothd. `system_profiler SPBluetoothDataType` reports
// device_batteryLevel* for Apple's own accessories (AirPods) and nothing for a
// generic BLE keyboard; ioreg carries no battery keys for it either; and the
// private BluetoothManager.framework — which is what the Settings pane uses —
// refuses to connect to bluetoothd from an unsigned binary (every property
// reads back 0/unavailable). What does work is asking the keyboard itself:
// it already exposes the standard GATT Battery Service (0x180F) and macOS lets
// CoreBluetooth attach to an already-connected peripheral, so we read
// characteristic 0x2A19 straight off the device.
//
// Attaching as a second GATT client does not disturb the HID link — the system
// keeps its own connection; ours is layered on the same one.
//
// Build: swiftc -O btbattery.swift -o btbattery

import Foundation
import CoreBluetooth

let match = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Keychron"
let BATT_SVC = CBUUID(string: "180F")
let BATT_CHR = CBUUID(string: "2A19")

func done(_ value: UInt8?, _ code: Int32 = 1) -> Never {
    if let v = value { print(v); exit(0) }
    exit(code)
}

final class Probe: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var central: CBCentralManager!
    private var target: CBPeripheral?   // strong ref: CBCentralManager doesn't keep one

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        // .unauthorized (3) means the parent process lacks the Bluetooth TCC grant.
        guard c.state == .poweredOn else {
            if c.state != .unknown && c.state != .resetting { done(nil, 3) }
            return
        }
        // Only peripherals the system already has a link to — we never scan,
        // so this costs nothing and can't connect to a stranger's device.
        let peers = c.retrieveConnectedPeripherals(withServices: [BATT_SVC])
        guard let p = peers.first(where: { ($0.name ?? "").localizedCaseInsensitiveContains(match) })
        else { done(nil, 2) }
        target = p
        p.delegate = self
        c.connect(p, options: nil)
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        p.discoverServices([BATT_SVC])
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        done(nil)
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let s = p.services?.first else { done(nil) }
        p.discoverCharacteristics([BATT_CHR], for: s)
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        guard error == nil, let ch = s.characteristics?.first else { done(nil) }
        p.readValue(for: ch)
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        done(ch.value?.first)
    }
}

let probe = Probe()
// Whole exchange is ~0.3s in practice; the ceiling only matters if the
// keyboard has gone to sleep mid-read.
DispatchQueue.main.asyncAfter(deadline: .now() + 6) { done(nil) }
RunLoop.main.run()
