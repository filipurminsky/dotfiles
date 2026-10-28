import AppKit
import CoreLocation
import CoreWLAN

final class SSIDHelper: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let cacheURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cache/sketchybar/wifi-ssid")

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        locationManager.delegate = self
        refreshSSID()

        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refreshSSID()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshSSID()
    }

    private func refreshSSID() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways else {
            if status == .notDetermined {
                locationManager.requestAlwaysAuthorization()
            }
            writeCache("")
            return
        }

        writeCache(CWWiFiClient.shared().interface()?.ssid() ?? "")
    }

    private func writeCache(_ ssid: String) {
        try? ssid.write(to: cacheURL, atomically: true, encoding: .utf8)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = SSIDHelper()
app.delegate = delegate
app.run()
