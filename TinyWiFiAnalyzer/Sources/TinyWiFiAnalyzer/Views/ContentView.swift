import SwiftUI
import CoreLocation

struct ContentView: View {
    @Bindable var viewModel: ScannerViewModel

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.bandViewModels.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.bandViewModels, id: \.band.id) { bandVM in
                            BandChartView(viewModel: bandVM)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(minWidth: 600, idealWidth: 900, minHeight: 400)
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 16) {
            // Location auth status
            HStack(spacing: 4) {
                Circle()
                    .fill(authStatusColor)
                    .frame(width: 6, height: 6)
                Text("Location: \(authStatusLabel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !viewModel.interfaceName.isEmpty {
                Text("Interface: \(viewModel.interfaceName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let totalNetworks = viewModel.bandViewModels.reduce(0) { $0 + $1.allSeriesData.count }
            Text("Networks: \(totalNetworks)")
                .font(.caption)
                .foregroundColor(.secondary)

            let ssidCount = viewModel.bandViewModels.reduce(0) { count, vm in
                count + vm.allSeriesData.filter { $0.ssid != "n/a" }.count
            }
            Text("SSIDs: \(ssidCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }

    private var authStatusColor: Color {
        switch viewModel.locationManager.authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse: .green
        case .denied, .restricted: .red
        case .notDetermined: .orange
        @unknown default: .gray
        }
    }

    private var authStatusLabel: String {
        switch viewModel.locationManager.authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse: "Granted"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .notDetermined: "Pending..."
        @unknown default: "Unknown"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning for Wi-Fi networks...")
                .foregroundColor(.secondary)

            let status = viewModel.locationManager.authorizationStatus
            if status == .denied || status == .restricted {
                VStack(spacing: 8) {
                    Text("Location Services permission is required to read Wi-Fi SSIDs.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                    Button("Open Location Preferences") {
                        viewModel.locationManager.openLocationPreferences()
                    }
                }
            } else if status == .notDetermined {
                VStack(spacing: 8) {
                    Text("Location Services permission required")
                        .foregroundColor(.orange)
                        .font(.callout)
                    Text("On macOS, you may need to manually enable Location Services for this app.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Button("Open System Settings") {
                        viewModel.locationManager.openLocationPreferences()
                    }
                }
            }
            Spacer()
        }
        .frame(minHeight: 300)
    }
}
