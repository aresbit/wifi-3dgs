import SwiftUI

enum SidebarPage: String, CaseIterable {
    case overview
    case spectrum
    case channels
    case interfaces
    case help
    case settings

    var label: String {
        switch self {
        case .overview:   String(localized: "Overview")
        case .spectrum:   String(localized: "Spectrum")
        case .channels:   String(localized: "Channels")
        case .interfaces: String(localized: "Interfaces")
        case .help:       String(localized: "Help")
        case .settings:   String(localized: "Settings")
        }
    }

    var icon: String {
        switch self {
        case .overview:   "house"
        case .spectrum:   "antenna.radiowaves.left.and.right"
        case .channels:   "chart.bar.fill"
        case .interfaces: "cable.connector"
        case .help:       "questionmark.circle"
        case .settings:   "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedPage: SidebarPage

    var body: some View {
        List(selection: $selectedPage) {
            Section {
                ForEach([SidebarPage.overview, .spectrum, .channels, .interfaces], id: \.self) { page in
                    Label(page.label, systemImage: page.icon)
                        .tag(page)
                }
            }
            Section {
                Label(SidebarPage.help.label, systemImage: SidebarPage.help.icon)
                    .tag(SidebarPage.help)
                Label(SidebarPage.settings.label, systemImage: SidebarPage.settings.icon)
                    .tag(SidebarPage.settings)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 160, idealWidth: 180)
        .navigationTitle("WiFi Lens")
    }
}
