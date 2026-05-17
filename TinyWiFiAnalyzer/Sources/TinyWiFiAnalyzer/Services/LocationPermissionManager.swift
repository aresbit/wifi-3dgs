import CoreLocation
import AppKit

@MainActor
@Observable
final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var showDeniedAlert = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus != .notDetermined {
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                showDeniedAlert = true
            }
            return
        }
        manager.requestWhenInUseAuthorization()
    }

    func pollStatus() {
        let status = manager.authorizationStatus
        if status != authorizationStatus {
            authorizationStatus = status
            if status == .denied || status == .restricted {
                showDeniedAlert = true
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .denied || status == .restricted {
                self.showDeniedAlert = true
            }
        }
    }

    func openLocationPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }

    func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
}
