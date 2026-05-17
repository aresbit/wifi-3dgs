import CoreWLAN

struct WiFiNetwork: Sendable, Identifiable {
    var id: String { "\(bssid)-\(channel.channelNumber)-\(channel.band.rawValue)" }
    let ssid: String?
    let bssid: String
    let rssi: Int
    let channel: WiFiChannel
    let isIBSS: Bool

    init(from cwNetwork: CWNetwork) {
        ssid = cwNetwork.ssid
        bssid = cwNetwork.bssid ?? "unknown"
        rssi = cwNetwork.rssiValue
        channel = WiFiChannel(from: cwNetwork.wlanChannel!)
        isIBSS = cwNetwork.ibss
    }
}
