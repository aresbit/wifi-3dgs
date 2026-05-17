import SwiftUI

@main
struct TinyWiFiAnalyzerApp: App {
    @State private var viewModel = ScannerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .alert("Location Services are disabled", isPresented: $viewModel.locationManager.showDeniedAlert) {
                    Button("Open Preferences") {
                        viewModel.locationManager.openLocationPreferences()
                    }
                    Button("Ignore", role: .cancel) {}
                    Button("Quit", role: .destructive) {
                        viewModel.locationManager.terminateApp()
                    }
                } message: {
                    Text("On macOS 14 Sonoma and Later, Location Services permission is required to get Wi-Fi SSIDs.\nPlease enable Location Services in System Preferences > Security & Privacy > Privacy > Location Services.")
                }
        }
        .windowResizability(.contentSize)
    }
}
