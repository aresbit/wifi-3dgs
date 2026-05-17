import SwiftUI

struct BandChartView: View {
    @Bindable var viewModel: BandChartViewModel

    private let leftAxisWidth: CGFloat = 40
    private let bottomAxisHeight: CGFloat = 24
    private let legendWidth: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            chartToolbar
            chartContent
        }
        .overlay {
            if viewModel.isExpanded {
                expandedOverlay
            }
        }
    }

    // MARK: - Toolbar

    private var chartToolbar: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.toggleFreeze()
            } label: {
                Image(systemName: viewModel.isFrozen ? "play.fill" : "pause.fill")
                    .frame(width: 24, height: 24)
            }
            .help(viewModel.isFrozen ? "Resume" : "Pause")

            Button {
                viewModel.showFilterPopover.toggle()
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .frame(width: 24, height: 24)
            }
            .help("Filter")
            .popover(isPresented: $viewModel.showFilterPopover) {
                FilterPopoverView(viewModel: viewModel)
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.hasFilter {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .offset(x: 4, y: 0)
                }
            }

            Button {
                viewModel.toggleExpand()
            } label: {
                Image(systemName: viewModel.isExpanded
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right")
                    .frame(width: 24, height: 24)
            }
            .help("Toggle Expand")

            if viewModel.zoomMin != nil {
                Button {
                    viewModel.resetZoom()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 24, height: 24)
                }
                .help("Reset Zoom")
            }

            Spacer()

            Text(viewModel.band.displayName)
                .font(.headline)

            Spacer()

            ExportMenuView(
                seriesData: viewModel.displayedSeriesData,
                band: viewModel.band,
                chartView: AnyView(chartContent)
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Group {
            if viewModel.isEmpty {
                VStack {
                    Spacer()
                    Text("Loading...")
                        .foregroundColor(Color(hex: "#888888"))
                        .font(.system(size: 16))
                    Spacer()
                }
                .frame(height: chartHeight)
            } else {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        legendPanel
                        chartCanvas
                    }
                    .gesture(zoomGesture(in: geometry))
                }
                .frame(height: chartHeight)
            }
        }
    }

    // MARK: - Legend Panel

    private var legendPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(viewModel.displayedSeriesData) { series in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(series.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Channel: \(series.channel) RSSI: \(series.rssi)dBm")
                                .font(.caption2)
                            Text(series.displaySSID)
                                .font(.caption)
                                .bold()
                            Text(series.bssid)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .opacity(series.isFilteredOut ? Constants.filteredOutOpacity : 1.0)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: legendWidth)
    }

    // MARK: - Canvas Chart

    private var chartCanvas: some View {
        Canvas { context, size in
            let chartRect = CGRect(
                x: leftAxisWidth, y: 0,
                width: size.width - leftAxisWidth,
                height: size.height - bottomAxisHeight
            )

            let xMin = viewModel.zoomMin ?? Double(xDataMin)
            let xMax = viewModel.zoomMax ?? Double(viewModel.band.maxChannel)
            let yMin = Double(Constants.rssiNoiseFloor)
            let yMax = 0.0

            let scaleX = chartRect.width / (xMax - xMin)
            let scaleY = chartRect.height / (yMax - yMin)

            func dataToPoint(channel: Double, rssi: Double) -> CGPoint {
                CGPoint(
                    x: chartRect.minX + (channel - xMin) * scaleX,
                    y: chartRect.maxY - (rssi - yMin) * scaleY
                )
            }

            let gridColor = Color.gray.opacity(0.15)

            // Horizontal grid (RSSI every 10 dBm)
            for rssiVal in stride(from: Int(yMin), through: Int(yMax), by: 10) {
                let rssi = Double(rssiVal)
                let y = chartRect.maxY - (rssi - yMin) * scaleY
                var line = Path()
                line.move(to: CGPoint(x: chartRect.minX, y: y))
                line.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                context.stroke(line, with: .color(gridColor), lineWidth: 1)

                context.draw(
                    Text("\(rssiVal)").font(.caption2).foregroundColor(.secondary),
                    at: CGPoint(x: chartRect.minX - 14, y: y)
                )
            }

            // Vertical grid (channel labels)
            let desiredTicks = min(viewModel.band.maxChannel - Int(xMin), 15)
            let rawStep = max(1, Int((xMax - xMin) / Double(desiredTicks)))
            let step = max(1, rawStep)
            for ch in stride(from: Int(xMin), through: Int(xMax), by: step) {
                if viewModel.band == .band24GHz && ch < 1 { continue }

                let x = chartRect.minX + (Double(ch) - xMin) * scaleX

                var line = Path()
                line.move(to: CGPoint(x: x, y: chartRect.minY))
                line.addLine(to: CGPoint(x: x, y: chartRect.maxY))
                context.stroke(line, with: .color(gridColor), lineWidth: 1)

                context.draw(
                    Text("\(ch)").font(.caption2).foregroundColor(.secondary),
                    at: CGPoint(x: x, y: chartRect.maxY + 12)
                )
            }

            // Axis lines
            var xAxis = Path()
            xAxis.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            xAxis.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
            context.stroke(xAxis, with: .color(.secondary), lineWidth: 1)

            var yAxis = Path()
            yAxis.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
            yAxis.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            context.stroke(yAxis, with: .color(.secondary), lineWidth: 1)

            // Axis titles
            context.draw(
                Text("dBm").font(.caption).foregroundColor(.secondary),
                at: CGPoint(x: 20, y: chartRect.midY)
            )
            context.draw(
                Text("channel").font(.caption).foregroundColor(.secondary),
                at: CGPoint(x: chartRect.midX, y: size.height - 4)
            )

            // Clip to chart area so curves don't overflow the axes
            let clipPath = Path(chartRect)
            context.clip(to: clipPath)

            // Draw each network as a Gaussian bell curve
            for series in viewModel.displayedSeriesData {
                let areaOpacity = series.isFilteredOut
                    ? Constants.filteredOutOpacity : 0.3
                let strokeOpacity = series.isFilteredOut
                    ? Constants.filteredOutOpacity : 0.6
                let curve = series.curvePoints

                guard curve.count >= 2 else { continue }

                var path = Path()
                path.move(to: dataToPoint(channel: curve[0].x, rssi: curve[0].y))
                for pt in curve.dropFirst() {
                    path.addLine(to: dataToPoint(channel: pt.x, rssi: pt.y))
                }
                // Close down to the noise floor
                path.addLine(to: dataToPoint(channel: Double(series.right), rssi: yMin))
                path.addLine(to: dataToPoint(channel: Double(series.left), rssi: yMin))
                path.closeSubpath()

                context.fill(path, with: .color(series.color.opacity(areaOpacity)))
                context.stroke(path, with: .color(series.color.opacity(strokeOpacity)), lineWidth: 1)
            }
        }
        .overlay {
            DataLabelOverlay(
                seriesData: viewModel.displayedSeriesData,
                leftAxisWidth: leftAxisWidth,
                bottomAxisHeight: bottomAxisHeight,
                xDataMin: xDataMin,
                xDataMax: viewModel.band.maxChannel,
                zoomMin: viewModel.zoomMin,
                zoomMax: viewModel.zoomMax
            )
        }
    }

    // MARK: - Zoom Gesture

    private func zoomGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                let startX = min(value.startLocation.x, value.location.x)
                let endX = max(value.startLocation.x, value.location.x)
                guard endX - startX > 20 else { return }

                let totalWidth = geometry.size.width
                let chartAreaLeft = leftAxisWidth + legendWidth
                let chartAreaWidth = totalWidth - chartAreaLeft
                guard chartAreaWidth > 0 else { return }

                let relStart = Swift.max(0.0, startX - chartAreaLeft)
                let relEnd = Swift.min(chartAreaWidth, endX - chartAreaLeft)

                let dataXMin = Double(xDataMin)
                let dataXMax = Double(viewModel.band.maxChannel)
                let dataRange = dataXMax - dataXMin

                let lo = dataXMin + (relStart / chartAreaWidth) * dataRange
                let hi = dataXMin + (relEnd / chartAreaWidth) * dataRange
                viewModel.applyZoom(lo: lo, hi: hi)
            }
    }

    // MARK: - Expanded Overlay

    private var expandedOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                chartToolbar
                HStack(spacing: 0) {
                    legendPanel
                    chartCanvas
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()

            Button {
                viewModel.toggleExpand()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var xDataMin: Int {
        // 2.4 GHz channels start at 1 but channel spans can go below (e.g. ch1 20MHz → span -1–3)
        viewModel.band == .band24GHz ? -1 : 1
    }
    private var chartHeight: CGFloat { 300 }
}

// MARK: - Data Label Overlay

private struct DataLabelOverlay: View {
    let seriesData: [ChartSeriesData]
    let leftAxisWidth: CGFloat
    let bottomAxisHeight: CGFloat
    let xDataMin: Int
    let xDataMax: Int
    let zoomMin: Double?
    let zoomMax: Double?

    var body: some View {
        GeometryReader { geometry in
            let chartRect = CGRect(
                x: leftAxisWidth, y: 0,
                width: geometry.size.width - leftAxisWidth,
                height: geometry.size.height - bottomAxisHeight
            )
            let xMin = zoomMin ?? Double(xDataMin)
            let xMax = zoomMax ?? Double(xDataMax)
            let scaleX = chartRect.width / (xMax - xMin)
            let yRange = 0.0 - Double(Constants.rssiNoiseFloor)
            let scaleY = chartRect.height / yRange

            ForEach(seriesData) { series in
                if !series.isFilteredOut {
                    let px = chartRect.minX + (Double(series.channel) - xMin) * scaleX
                    let py = chartRect.maxY - (Double(series.rssi) - Double(Constants.rssiNoiseFloor)) * scaleY - 10
                    Text("\(series.channel) \(series.displaySSID)")
                        .font(.system(size: 9))
                        .foregroundColor(series.color)
                        .position(x: px, y: py)
                }
            }
        }
    }
}
