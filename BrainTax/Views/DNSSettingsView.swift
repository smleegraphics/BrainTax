//
//  DNSSettingsView.swift
//  BrainTax
//
//  Settings view for NextDNS configuration
//

import SwiftUI

struct DNSSettingsView: View {
    @AppStorage("nextdns_profile_id") private var profileId = ""
    @AppStorage("nextdns_api_key") private var apiKey = ""

    @State private var testStatus: TestStatus = .idle
    @State private var showingAPIKeyInfo = false

    enum TestStatus: Equatable {
        case idle
        case testing
        case success
        case error(String)
    }

    var body: some View {
        Form {
            Section {
                TextField("Profile ID", text: $profileId)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                SecureField("API Key", text: $apiKey)
                    .textContentType(.none)
                    .autocorrectionDisabled()
            } header: {
                Text("NextDNS Credentials")
            } footer: {
                Text("Find these in your NextDNS account settings.")
            }

            Section {
                Button {
                    showingAPIKeyInfo = true
                } label: {
                    Label("How to get your API Key", systemImage: "questionmark.circle")
                }
            }

            Section {
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        switch testStatus {
                        case .idle:
                            EmptyView()
                        case .testing:
                            ProgressView()
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .error:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .disabled(profileId.isEmpty || apiKey.isEmpty || testStatus == .testing)

                if case .error(let message) = testStatus {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if testStatus == .success {
                    Text("Connected successfully!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Section {
                NavigationLink("Manage Blocked Apps") {
                    BlockedAppsView()
                }
                .disabled(!isConfigured)
            } header: {
                Text("Blocking")
            } footer: {
                if !isConfigured {
                    Text("Configure NextDNS credentials first.")
                }
            }
        }
        .navigationTitle("DNS Settings")
        .sheet(isPresented: $showingAPIKeyInfo) {
            APIKeyInfoView()
        }
    }

    private var isConfigured: Bool {
        !profileId.isEmpty && !apiKey.isEmpty
    }

    private func testConnection() async {
        testStatus = .testing

        let controller = NextDNSController(profileId: profileId, apiKey: apiKey)

        do {
            // Try to fetch parental control services to verify credentials work
            let services = try await controller.fetchAvailableServices()
            print("Available services: \(services)")
            testStatus = .success
        } catch {
            testStatus = .error(error.localizedDescription)
        }
    }
}

// MARK: - API Key Info View

struct APIKeyInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Your NextDNS Credentials")
                        .font(.title2)
                        .fontWeight(.bold)

                    Group {
                        Text("Profile ID")
                            .font(.headline)
                        Text("1. Go to my.nextdns.io")
                        Text("2. Your Profile ID is in the URL: my.nextdns.io/**abc123**/setup")
                        Text("3. It's also shown on the Setup tab")
                    }

                    Divider()

                    Group {
                        Text("API Key")
                            .font(.headline)
                        Text("1. Go to my.nextdns.io")
                        Text("2. Click your email (top right) → Account")
                        Text("3. Scroll to \"API\" section")
                        Text("4. Click \"Generate\" or copy existing key")
                    }

                    Divider()

                    Text("Make sure the NextDNS profile is installed on your iPhone (Settings → General → VPN & Device Management).")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Blocked Apps View

struct BlockedAppsView: View {
    @State private var blockedApps: Set<String> = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var isToggling: Set<String> = []

    let apps = NextDNSAppIds.allApps

    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Checking status...")
                        Spacer()
                    }
                } else if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task { await loadBlockedStatus() }
                    }
                } else {
                    ForEach(apps, id: \.self) { app in
                        HStack {
                            Text(app)
                            Spacer()
                            if isToggling.contains(app) {
                                ProgressView()
                                    .controlSize(.small)
                            } else if blockedApps.contains(app.lowercased()) {
                                Text("Blocked")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Button("Unblock") {
                                    Task { await toggleBlock(app: app, block: false) }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Text("Allowed")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Button("Block") {
                                    Task { await toggleBlock(app: app, block: true) }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            } footer: {
                Text("Uses NextDNS Parental Control to block app domains. Changes take effect within seconds.")
            }
        }
        .navigationTitle("Blocked Apps")
        .refreshable {
            await loadBlockedStatus()
        }
        .task {
            await loadBlockedStatus()
        }
    }

    private func loadBlockedStatus() async {
        isLoading = true
        error = nil

        let controller = NextDNSController()
        guard controller.isConfigured else {
            error = "NextDNS not configured"
            isLoading = false
            return
        }

        var blocked: Set<String> = []

        for app in apps {
            do {
                if try await controller.isAppBlocked(name: app) {
                    blocked.insert(app.lowercased())
                }
            } catch {
                // Continue checking other apps
            }
        }

        blockedApps = blocked
        isLoading = false
    }

    private func toggleBlock(app: String, block: Bool) async {
        let controller = NextDNSController()
        isToggling.insert(app)
        error = nil

        do {
            if block {
                try await controller.blockApp(name: app)
                blockedApps.insert(app.lowercased())
            } else {
                try await controller.unblockApp(name: app)
                blockedApps.remove(app.lowercased())
            }
        } catch {
            self.error = "\(app): \(error.localizedDescription)"
        }

        isToggling.remove(app)
    }
}

#Preview {
    NavigationView {
        DNSSettingsView()
    }
}
