import CoreWLAN
import Foundation

actor WiFiScanner {
    private let client = CWWiFiClient.shared()

    private var shouldStop = false

    /// Emits scan results at the configured interval.
    func startScanning(interval: Duration = Constants.scanInterval) -> AsyncStream<[WiFiNetwork]> {
        AsyncStream { continuation in
            let task = Task {
                while !shouldStop {
                    let networks: Set<CWNetwork> = (try? client.interface()?
                        .scanForNetworks(withSSID: nil)) ?? []
                    let wrapped = networks.map { WiFiNetwork(from: $0) }
                    continuation.yield(wrapped)
                    do {
                        try await Task.sleep(for: interval)
                    } catch {
                        // Log error but continue scanning
                        print("Wi-Fi scan failed: \(error)")
                    }
                    try? await Task.sleep(for: interval)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func stopScanning() {
        shouldStop = true
    }

    func interfaceName() -> String? {
        client.interface()?.interfaceName
    }

    func supportedBands() -> Set<ChannelBand> {
        guard let channels = client.interface()?.supportedWLANChannels() else {
            return Set(ChannelBand.allCases)
        }
        var bands = Set<ChannelBand>()
        for channel in channels {
            if let band = ChannelBand(rawValue: channel.channelBand.rawValue) {
                bands.insert(band)
            }
        }
        return bands
    }
}
