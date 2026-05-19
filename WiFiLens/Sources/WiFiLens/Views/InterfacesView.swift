import SwiftUI

struct InterfacesView: View {
    let interfaces: [NetworkInterfaceInfo]

    var body: some View {
        if interfaces.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "wifi.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No network interfaces found")
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(interfaces, id: \.interfaceName) { iface in
                        InterfaceCard(info: iface)
                    }
                }
                .padding(20)
            }
        }
    }
}

private struct InterfaceCard: View {
    let info: NetworkInterfaceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: info.ssid != nil ? "wifi" : "cable.connector")
                    .font(.title3)
                    .foregroundColor(info.ssid != nil ? .accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.ssid ?? info.interfaceName)
                        .font(.headline)
                    Text(info.interfaceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if info.ssid != nil {
                    Text(info.displayRSSI)
                        .font(.callout.monospaced())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Wi-Fi details
            if info.ssid != nil {
                kvTable([
                    ("BSSID", info.displayBSSID),
                    ("Channel", info.displayChannel),
                    ("Tx Rate", info.displayTxRate),
                    ("PHY Mode", info.displayPhyMode),
                    ("Security", info.displaySecurity),
                ])
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()
            }

            // Network details
            kvTable([
                ("Hardware MAC", info.displayMAC),
                ("IPv4 Address", info.displayIP),
                ("Subnet Mask", info.displaySubnet),
                ("Router", info.displayRouter),
                ("DNS", info.displayDNS),
            ])
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private struct KVPair: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private func kvTable(_ pairs: [(String, String)]) -> some View {
        let items = pairs.map { KVPair(label: $0.0, value: $0.1) }
        return Grid(horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(items) { item in
                GridRow {
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .gridColumnAlignment(.trailing)
                    Text(item.value)
                        .font(.callout)
                        .textSelection(.enabled)
                        .gridColumnAlignment(.leading)
                }
            }
        }
    }
}
