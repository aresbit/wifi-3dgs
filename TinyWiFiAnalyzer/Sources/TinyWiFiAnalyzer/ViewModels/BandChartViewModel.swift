import SwiftUI

@MainActor
@Observable
final class BandChartViewModel {
    let band: ChannelBand

    var filterQuery: String = ""
    var isFrozen: Bool = false
    var isExpanded: Bool = false
    var zoomMin: Double?
    var zoomMax: Double?
    var showFilterPopover: Bool = false

    private(set) var allSeriesData: [ChartSeriesData] = []
    private(set) var displayedSeriesData: [ChartSeriesData] = []
    private(set) var interfaceName: String = ""

    var hasFilter: Bool { !filterQuery.trimmingCharacters(in: .whitespaces).isEmpty }
    var isEmpty: Bool { allSeriesData.isEmpty }

    init(band: ChannelBand) {
        self.band = band
    }

    func updateNetworks(_ networks: [WiFiNetwork], colorHasher: SSIDColorHasher) {
        let dataArray = ChannelSpanCalculator.toSeriesData(networks, colorHasher: colorHasher)
        allSeriesData = dataArray
        if !isFrozen {
            applyFilter()
        }
    }

    func updateInterfaceName(_ name: String) {
        interfaceName = name
    }

    func applyFilter() {
        let needle = filterQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if needle.isEmpty {
            displayedSeriesData = allSeriesData.map { s in
                var s = s
                s.isFilteredOut = false
                return s
            }
        } else {
            displayedSeriesData = allSeriesData.map { s in
                var s = s
                s.isFilteredOut = !(s.ssid.lowercased().contains(needle)
                    || s.bssid.lowercased().contains(needle))
                return s
            }
        }
    }

    func toggleFreeze() {
        isFrozen.toggle()
        if !isFrozen {
            applyFilter()
        }
    }

    func toggleExpand() {
        isExpanded.toggle()
    }

    func clearFilter() {
        filterQuery = ""
        applyFilter()
        showFilterPopover = false
    }

    func resetZoom() {
        zoomMin = nil
        zoomMax = nil
    }

    func applyZoom(lo: Double, hi: Double) {
        let clampedMin = Swift.max(Double(band == .band24GHz ? 1 : 1), lo)
        let clampedMax = Swift.min(Double(band.maxChannel), hi)
        let range = clampedMax - clampedMin
        guard range >= Double(Constants.minZoomRange) else { return }
        zoomMin = clampedMin
        zoomMax = clampedMax
    }
}
