//
//  DNSBlockingController.swift
//  BrainTax
//
//  NextDNS API integration for app blocking via Parental Control
//

import Foundation

/// NextDNS API integration using Parental Control for reliable app blocking
class NextDNSController {
    private let profileId: String
    private let apiKey: String
    private let baseURL = "https://api.nextdns.io"

    var isConfigured: Bool {
        !profileId.isEmpty && !apiKey.isEmpty
    }

    init(profileId: String, apiKey: String) {
        self.profileId = profileId
        self.apiKey = apiKey
    }

    /// Convenience init from UserDefaults
    convenience init() {
        let profileId = UserDefaults.standard.string(forKey: "nextdns_profile_id") ?? ""
        let apiKey = UserDefaults.standard.string(forKey: "nextdns_api_key") ?? ""
        self.init(profileId: profileId, apiKey: apiKey)
    }

    // MARK: - Public API

    func blockApp(name: String) async throws {
        guard let appId = NextDNSAppIds.appId(for: name) else {
            throw DNSError.apiError("Unknown app: \(name)")
        }
        try await addParentalControlService(appId: appId)
    }

    func unblockApp(name: String) async throws {
        guard let appId = NextDNSAppIds.appId(for: name) else {
            throw DNSError.apiError("Unknown app: \(name)")
        }
        try await removeParentalControlService(appId: appId)
    }

    func isAppBlocked(name: String) async throws -> Bool {
        guard let appId = NextDNSAppIds.appId(for: name) else { return false }
        let services = try await getParentalControlServices()
        return services.first { $0.id == appId }?.active ?? false
    }

    /// Fetches all available parental control service IDs (for debugging)
    func fetchAvailableServices() async throws -> [String] {
        let services = try await getParentalControlServices()
        return services.map { $0.id }
    }

    // MARK: - Private API Calls

    private func addParentalControlService(appId: String) async throws {
        // First try PATCH to update existing
        let patchUrl = URL(string: "\(baseURL)/profiles/\(profileId)/parentalControl/services/\(appId)")!
        var patchRequest = URLRequest(url: patchUrl)
        patchRequest.httpMethod = "PATCH"
        patchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchRequest.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        patchRequest.httpBody = try JSONEncoder().encode(["active": true])

        let (_, patchResponse) = try await URLSession.shared.data(for: patchRequest)

        if let httpResponse = patchResponse as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
            return
        }

        // If PATCH failed, try POST to add new service
        let postUrl = URL(string: "\(baseURL)/profiles/\(profileId)/parentalControl/services")!
        var postRequest = URLRequest(url: postUrl)
        postRequest.httpMethod = "POST"
        postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        postRequest.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        postRequest.httpBody = try JSONEncoder().encode(ParentalControlUpdate(id: appId, active: true))

        let (postData, postResponse) = try await URLSession.shared.data(for: postRequest)

        guard let httpResponse = postResponse as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: postData, encoding: .utf8) ?? "No body"
            throw DNSError.apiError("HTTP \((postResponse as? HTTPURLResponse)?.statusCode ?? 0): \(responseBody)")
        }
    }

    private func removeParentalControlService(appId: String) async throws {
        let url = URL(string: "\(baseURL)/profiles/\(profileId)/parentalControl/services/\(appId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 404 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No body"
            throw DNSError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0): \(responseBody)")
        }
    }

    private func getParentalControlServices() async throws -> [ParentalControlService] {
        let url = URL(string: "\(baseURL)/profiles/\(profileId)/parentalControl/services")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw DNSError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0): \(body)")
        }

        let result = try JSONDecoder().decode(ParentalControlResponse.self, from: data)
        return result.data
    }
}

// MARK: - Models

private struct ParentalControlUpdate: Codable {
    let id: String
    let active: Bool
}

private struct ParentalControlService: Codable {
    let id: String
    let active: Bool
}

private struct ParentalControlResponse: Codable {
    let data: [ParentalControlService]
}

// MARK: - App IDs

enum NextDNSAppIds {
    static func appId(for name: String) -> String? {
        switch name.lowercased() {
        case "instagram": return "instagram"
        case "tiktok": return "tiktok"
        case "twitter", "x", "twitter/x": return "twitter"
        case "facebook": return "facebook"
        case "youtube": return "youtube"
        case "reddit": return "reddit"
        case "snapchat": return "snapchat"
        default: return nil
        }
    }

    static let allApps = ["Instagram", "TikTok", "Twitter", "Facebook", "YouTube", "Reddit", "Snapchat"]
}

// MARK: - Errors

enum DNSError: Error, LocalizedError {
    case apiError(String)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        case .notConfigured: return "NextDNS is not configured"
        }
    }
}
