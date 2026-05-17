import SwiftUI

struct FilterPopoverView: View {
    @Bindable var viewModel: BandChartViewModel

    var body: some View {
        HStack(spacing: 8) {
            TextField("Filter by SSID or MAC/BSSID", text: $viewModel.filterQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .onChange(of: viewModel.filterQuery) {
                    viewModel.applyFilter()
                }

            Button("Clear") {
                viewModel.clearFilter()
            }
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .padding(8)
        .frame(width: 300)
    }
}
