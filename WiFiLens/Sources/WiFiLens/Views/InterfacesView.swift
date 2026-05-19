import SwiftUI
import CoreWLAN

enum InterfaceViewMode: String, CaseIterable {
    case simple  = "Simple"
    case details = "Details"
}

struct InterfacesView: View {
    let interfaces: [NetworkInterfaceInfo]
    let scannerViewModel: ScannerViewModel
    @State private var mode: InterfaceViewMode = .simple

    private var wifiInterface: NetworkInterfaceInfo? {
        interfaces.first(where: { $0.ssid != nil })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle
            HStack {
                Picker("", selection: $mode) {
                    ForEach(InterfaceViewMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 160)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if interfaces.isEmpty {
                Spacer()
                Image(systemName: "wifi.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No network interfaces found")
                    .foregroundColor(.secondary)
                Spacer()
            } else if mode == .simple {
                dashboardView
            } else {
                detailsView
            }
        }
    }

    // MARK: - Dashboard (Simple)

    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let wifi = wifiInterface {
                    connectionHero(wifi)
                    healthIndicators(wifi)
                    linkDetails(wifi)
                }

                let others = interfaces.filter { $0.ssid == nil && $0.ipv4Addresses.first != nil }
                if !others.isEmpty {
                    otherInterfaces(others)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: 640)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hero

    private func connectionHero(_ wifi: NetworkInterfaceInfo) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "wifi")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wifi.displaySSID)
                        .font(.title3)
                        .fontWeight(.semibold)
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("· \(wifi.interfaceName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(bandLabel(wifi))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(channelLabel(wifi))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Health Indicators

    private func healthIndicators(_ wifi: NetworkInterfaceInfo) -> some View {
        HStack(spacing: 12) {
            // RSSI
            indicatorPill(
                title: "RSSI",
                value: wifi.displayRSSI,
                subtitle: nil,
                color: rssiColor(wifi.rssi ?? -100),
                bar: rssiBar(wifi.rssi ?? -100)
            )

            // PHY Mode
            indicatorPill(
                title: "PHY Mode",
                value: wifi.displayPhyMode,
                subtitle: wifiModelabel(wifi),
                color: .accentColor,
                bar: nil
            )

            // Stability
            let stab = stability(wifi)
            indicatorPill(
                title: "Stability",
                value: stab.label,
                subtitle: "\(stab.score)/100",
                color: stab.color,
                bar: scoreBar(stab.score, color: stab.color)
            )
        }
    }

    private func indicatorPill(title: String, value: String, subtitle: String?, color: Color, bar: AnyView?) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(title).font(.system(size: 9)).foregroundColor(.secondary)
            Spacer().frame(height: 6)
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(color)
            Spacer().frame(height: 4)
            if let sub = subtitle {
                Text(sub).font(.system(size: 10)).foregroundColor(.secondary)
            }
            Spacer().frame(height: 4)
            if let bar = bar {
                bar.padding(.horizontal, 12)
            } else {
                Rectangle().fill(.clear).frame(height: 4)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Link Details

    private func linkDetails(_ wifi: NetworkInterfaceInfo) -> some View {
        HStack(alignment: .top, spacing: 24) {
            kvTable([
                ("BSSID", wifi.displayBSSID),
                ("Security", wifi.displaySecurity),
                ("MCS / NSS", mcsNssLabel(wifi)),
                ("Tx Rate", wifi.displayTxRate),
                ("k / r / v", kvrLabel(wifi)),
            ])
            kvTable([
                ("IPv4", wifi.displayIP),
                ("Subnet", wifi.displaySubnet),
                ("Router", wifi.displayRouter),
                ("DNS", wifi.displayDNS),
                ("MAC", wifi.displayMAC),
            ])
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Other Interfaces

    private func otherInterfaces(_ others: [NetworkInterfaceInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other Interfaces")
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 4) {
                ForEach(others, id: \.interfaceName) { iface in
                    HStack(spacing: 8) {
                        Image(systemName: "cable.connector")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(iface.interfaceName)
                            .font(.callout)
                        Spacer()
                        Text(iface.displayIP)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // MARK: - Details (Professional)

    private var detailsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(interfaces, id: \.interfaceName) { iface in
                    InterfaceCard(info: iface)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Helpers

    private func kvTable(_ pairs: [(String, String)]) -> some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 4) {
            ForEach(pairs, id: \.0) { label, value in
                GridRow {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .gridColumnAlignment(.trailing)
                    Text(value)
                        .font(.callout)
                        .textSelection(.enabled)
                        .gridColumnAlignment(.leading)
                }
            }
        }
    }

    private func bandLabel(_ wifi: NetworkInterfaceInfo) -> String {
        guard let ch = wifi.channel else { return "—" }
        if ch <= 14 { return "2.4 GHz" }
        if ch <= 170 { return "5 GHz" }
        return "6 GHz"
    }

    private func channelLabel(_ wifi: NetworkInterfaceInfo) -> String {
        guard let ch = wifi.channel else { return "—" }
        return "Channel \(ch)"
    }

    private func rssiColor(_ rssi: Int) -> Color {
        if rssi >= -50 { return .green }
        if rssi >= -70 { return .yellow }
        if rssi >= -85 { return .orange }
        return .red
    }

    private func rssiBar(_ rssi: Int) -> AnyView {
        let pct = max(0.0, min(1.0, Double(rssi + 100) / 70.0))
        return AnyView(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(.quaternary).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(rssiColor(rssi))
                        .frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)
        )
    }

    private func scoreBar(_ score: Int, color: Color) -> AnyView {
        AnyView(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(.quaternary).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 4)
                }
            }
            .frame(height: 4)
        )
    }

    private func stability(_ wifi: NetworkInterfaceInfo) -> (score: Int, label: String, color: Color) {
        let rssi = wifi.rssi ?? -100
        var score = 0
        if rssi >= -50 { score += 40 }
        else if rssi >= -70 { score += 30 }
        else if rssi >= -85 { score += 15 }

        // Trend bonus from signal history
        let bssid = wifi.bssid ?? ""
        if let trend = scannerViewModel.signalHistory.trend(for: bssid) {
            switch trend.direction {
            case .up:   score += 15
            case .down: score += 0
            case .stable:
                if abs(trend.delta) <= 2 { score += 15 }
                else { score += 5 }
            }
        }

        // Protocol bonus
        let ie = scannerViewModel.lastNetworks
            .first(where: { $0.bssid == bssid })
            .flatMap { $0.ieData.map { IEParser.parse(data: $0) } }
        let k = ie?.supports80211k ?? false
        let r = ie?.supports80211r ?? false
        let v = ie?.supports80211v ?? false
        let protoCount = [k, r, v].filter { $0 }.count
        score += [0, 7, 14, 20][protoCount]

        // Width bonus
        if let iface = CWWiFiClient.shared().interface() {
            let width = iface.wlanChannel()?.channelWidth.rawValue ?? 20
            if width >= 80 { score += 15 }
            else if width >= 40 { score += 10 }
        }

        score = min(100, score)
        let label: String = switch score {
        case 85...:  "Excellent"
        case 70...:  "Good"
        case 50...:  "Moderate"
        default:     "Weak"
        }
        let color: Color = switch score {
        case 85...: .green
        case 70...: .mint
        case 50...: .orange
        default:    .red
        }
        return (score, label, color)
    }

    private func wifiModelabel(_ wifi: NetworkInterfaceInfo) -> String {
        switch wifi.displayPhyMode {
        case "802.11be": return "Wi‑Fi 7"
        case "802.11ax": return "Wi‑Fi 6"
        case "802.11ac": return "Wi‑Fi 5"
        case "802.11n":  return "Wi‑Fi 4"
        default: return wifi.displayPhyMode
        }
    }

    private func mcsNssLabel(_ wifi: NetworkInterfaceInfo) -> String {
        let bssid = wifi.bssid ?? ""
        let ie = scannerViewModel.lastNetworks
            .first(where: { $0.bssid == bssid })
            .flatMap { $0.ieData.map { IEParser.parse(data: $0) } }
        let mcs = ie?.mcsSummary ?? ""
        let nss = ie?.nssSummary ?? ""
        if mcs.isEmpty && nss.isEmpty { return "—" }
        return "MCS \(mcs) / NSS \(nss)"
    }

    private func kvrLabel(_ wifi: NetworkInterfaceInfo) -> String {
        let bssid = wifi.bssid ?? ""
        let ie = scannerViewModel.lastNetworks
            .first(where: { $0.bssid == bssid })
            .flatMap { $0.ieData.map { IEParser.parse(data: $0) } }
        guard let ie else { return "—" }
        var parts: [String] = []
        if ie.supports80211k { parts.append("k") }
        if ie.supports80211r { parts.append("r") }
        if ie.supports80211v { parts.append("v") }
        return parts.isEmpty ? "—" : parts.joined(separator: " / ")
    }
}

// MARK: - Interface Card (Details mode)

private struct InterfaceCard: View {
    let info: NetworkInterfaceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            if info.ssid != nil {
                Grid(horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        Text("BSSID").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                        Text(info.displayBSSID).font(.callout).textSelection(.enabled).gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Channel").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                        Text(info.displayChannel).font(.callout).gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Tx Rate").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                        Text(info.displayTxRate).font(.callout).gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("PHY Mode").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                        Text(info.displayPhyMode).font(.callout).gridColumnAlignment(.leading)
                    }
                    GridRow {
                        Text("Security").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                        Text(info.displaySecurity).font(.callout).gridColumnAlignment(.leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Divider()
            }

            Grid(horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Hardware MAC").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text(info.displayMAC).font(.callout).textSelection(.enabled).gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("IPv4 Address").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text(info.displayIP).font(.callout).gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Subnet Mask").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text(info.displaySubnet).font(.callout).gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("Router").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text(info.displayRouter).font(.callout).gridColumnAlignment(.leading)
                }
                GridRow {
                    Text("DNS").font(.caption).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text(info.displayDNS).font(.callout).gridColumnAlignment(.leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
