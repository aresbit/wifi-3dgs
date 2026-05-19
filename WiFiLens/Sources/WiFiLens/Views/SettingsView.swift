import SwiftUI
import Sparkle

struct SettingsView: View {
    let updater: SparkleUpdater

    @State private var autoCheck: Bool
    @AppStorage("scanIntervalSeconds") private var scanInterval: Int = 3
    @AppStorage("mcpEnabled") private var mcpEnabled: Bool = false
    @AppStorage("mcpPort") private var mcpPort: Int = 19840

    init(updater: SparkleUpdater) {
        self.updater = updater
        _autoCheck = State(initialValue: updater.automaticallyChecksForUpdates)
    }

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            mcpTab
                .tabItem { Label("MCP", systemImage: "apple.terminal") }
            updatesTab
                .tabItem { Label("Updates", systemImage: "arrow.down.circle") }
        }
        .frame(width: 420, height: 300)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WiFi Lens")
                        .font(.headline)
                    Text("A simple Wi-Fi channel and signal strength analyzer for macOS.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Scan Interval") {
                Picker("Refresh interval", selection: $scanInterval) {
                    Text("1 second").tag(1)
                    Text("2 seconds").tag(2)
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - MCP

    private var mcpTab: some View {
        Form {
            Section {
                Toggle("Enable MCP server", isOn: $mcpEnabled)
                Text("Expose current Wi-Fi scan data as a local HTTP API for AI tools (Claude Desktop, etc.) to query via MCP.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Connection") {
                HStack {
                    Text("Port:")
                    TextField("", value: $mcpPort, format: .number)
                        .frame(width: 80)
                    Stepper("", value: $mcpPort, in: 1024...65535)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude Desktop config")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(#"{"mcpServers":{"wifi-lens":{"command":"WiFiLensMCP","args":["\#(mcpPort)"]}}}"#)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Updates

    private var updatesTab: some View {
        Form {
            Section {
                Toggle("Automatically check for updates", isOn: $autoCheck)
                    .onChange(of: autoCheck) { _, newValue in
                        updater.automaticallyChecksForUpdates = newValue
                    }
            }

            Section {
                HStack {
                    Button("Check Now") {
                        updater.checkForUpdates()
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }
}
