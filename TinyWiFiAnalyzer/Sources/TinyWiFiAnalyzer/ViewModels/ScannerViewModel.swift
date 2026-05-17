import SwiftUI

@MainActor
@Observable
final class ScannerViewModel {
    let scanner = WiFiScanner()
    var locationManager = LocationPermissionManager()
    let colorHasher = SSIDColorHasher()

    var band24 = BandChartViewModel(band: .band24GHz)
    var band5 = BandChartViewModel(band: .band5GHz)
    var band6 = BandChartViewModel(band: .band6GHz)

    var supportedBands: Set<ChannelBand> = []
    var isScanning = false
    var interfaceName: String = ""

    var bandViewModels: [BandChartViewModel] {
        [band24, band5, band6].filter { supportedBands.contains($0.band) }
    }

    private var scanTask: Task<Void, Never>?

    func start() async {
        locationManager.requestPermission()
        supportedBands = await scanner.supportedBands()

        if let name = await scanner.interfaceName() {
            interfaceName = name
            for vm in bandViewModels {
                vm.updateInterfaceName(name)
            }
        }

        isScanning = true
        scanTask = Task {
            let stream = await scanner.startScanning()
            for await networks in stream {
                guard !Task.isCancelled else { break }

                // Poll location status each scan cycle
                locationManager.pollStatus()

                let sorted24 = networks
                    .filter { $0.channel.band == .band24GHz }
                    .sorted { $0.channel.channelNumber < $1.channel.channelNumber }
                if supportedBands.contains(.band24GHz) {
                    band24.updateNetworks(sorted24, colorHasher: colorHasher)
                }

                let sorted5 = networks
                    .filter { $0.channel.band == .band5GHz }
                    .sorted { $0.channel.channelNumber < $1.channel.channelNumber }
                if supportedBands.contains(.band5GHz) {
                    band5.updateNetworks(sorted5, colorHasher: colorHasher)
                }

                let sorted6 = networks
                    .filter { $0.channel.band == .band6GHz }
                    .sorted { $0.channel.channelNumber < $1.channel.channelNumber }
                if supportedBands.contains(.band6GHz) {
                    band6.updateNetworks(sorted6, colorHasher: colorHasher)
                }

                if let name = await scanner.interfaceName() {
                    interfaceName = name
                    for vm in bandViewModels {
                        vm.updateInterfaceName(name)
                    }
                }
            }
        }
    }

    func stop() {
        scanTask?.cancel()
        isScanning = false
        Task { await scanner.stopScanning() }
    }
}
