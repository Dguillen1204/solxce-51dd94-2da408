// Models/BackendSyncService.swift
import Foundation
import SwiftUI
import Combine

/// BackendSyncService manages cloud synchronization and account session handling
/// using the generated 10x backend clients (TenxAuth, BackendClient, TenxData, TenxStorage).
@MainActor
public final class BackendSyncService: ObservableObject {
    public static let shared = BackendSyncService()

    @Published public var currentUser: TenxAuthUser?
    @Published public var currentSession: TenxAuthSession?
    @Published public var accessToken: String?
    @Published public var isAuthenticated: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTime: Date?
    @Published public var syncErrorMessage: String?

    private let auth = TenxAuth()
    private let backend = BackendClient()
    private let data = TenxData()
    private let storage = TenxStorage()

    private let tokenKey = "solxce_auth_access_token"
    private let refreshKey = "solxce_auth_refresh_token"

    private init() {
        restoreSessionIfAvailable()
    }

    // MARK: - Session & Authentication

    public func restoreSessionIfAvailable() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty else {
            return
        }

        Task {
            do {
                let session = try await auth.session(accessToken: token)
                self.currentSession = session
                self.accessToken = token
                self.isAuthenticated = true
            } catch {
                // If access token expired, attempt refresh
                if let refreshToken = UserDefaults.standard.string(forKey: refreshKey) {
                    do {
                        let response = try await auth.refresh(refreshToken: refreshToken)
                        self.storeSession(response: response)
                    } catch {
                        self.signOut()
                    }
                } else {
                    self.signOut()
                }
            }
        }
    }

    public func signUp(email: String, password: String) async throws -> TenxAuthResponse {
        let response = try await auth.signUp(email: email, password: password)
        storeSession(response: response)
        return response
    }

    public func signIn(email: String, password: String) async throws -> TenxAuthResponse {
        let response = try await auth.signIn(email: email, password: password)
        storeSession(response: response)
        return response
    }

    public func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshKey)
        self.currentUser = nil
        self.currentSession = nil
        self.accessToken = nil
        self.isAuthenticated = false
    }

    private func storeSession(response: TenxAuthResponse) {
        self.currentUser = response.user
        self.currentSession = response.session
        self.accessToken = response.accessToken
        self.isAuthenticated = true

        UserDefaults.standard.set(response.accessToken, forKey: tokenKey)
        if let refresh = response.refreshToken {
            UserDefaults.standard.set(refresh, forKey: refreshKey)
        }
    }

    // MARK: - Backend Client API Calls

    /// Fetches server health check status through BackendClient
    public func checkBackendHealth() async -> Bool {
        do {
            struct HealthResponse: Codable {
                let status: String?
            }
            let res = try await backend.get(HealthResponse.self, path: "healthz", accessToken: accessToken)
            return res.status == "ok" || res.status != nil
        } catch {
            return false
        }
    }

    /// Calls custom backend workout analytics / AI summary endpoint via authenticated BackendClient
    public func fetchCloudAnalytics() async throws -> [String: String]? {
        guard let token = accessToken else { return nil }
        return try await backend.get([String: String].self, path: "analytics/summary", accessToken: token)
    }

    /// Sends completed workout payload to backend API endpoint via BackendClient
    public func recordWorkoutEvent(title: String, durationMinutes: Int, calories: Int) async throws -> Bool {
        guard let token = accessToken else { return false }
        struct WorkoutEventPayload: Encodable {
            let title: String
            let duration_minutes: Int
            let calories_burned: Int
            let completed_at: String
        }
        struct WorkoutEventResponse: Decodable {
            let success: Bool?
        }
        let payload = WorkoutEventPayload(
            title: title,
            duration_minutes: durationMinutes,
            calories_burned: calories,
            completed_at: ISO8601DateFormatter().string(from: Date())
        )
        let response = try await backend.send(
            WorkoutEventResponse.self,
            path: "workouts/record",
            method: "POST",
            body: payload,
            accessToken: token
        )
        return response.success ?? true
    }

    // MARK: - TenxData Database Sync

    /// Syncs local profile metadata to Neon database via TenxData
    public func syncProfileData(name: String, handle: String, athleteType: String) async {
        guard let token = accessToken else { return }
        self.isSyncing = true
        defer { self.isSyncing = false }

        struct ProfileSyncPayload: Encodable {
            let name: String
            let handle: String
            let athlete_type: String
            let updated_at: String
        }

        let payload = ProfileSyncPayload(
            name: name,
            handle: handle,
            athlete_type: athleteType,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            _ = try await data.insert(table: "profiles", value: payload, accessToken: token)
            self.lastSyncTime = Date()
            self.syncErrorMessage = nil
        } catch {
            self.syncErrorMessage = error.localizedDescription
        }
    }

    // MARK: - TenxStorage Media Uploads

    /// Requests upload authorization for media assets
    public func requestMediaUploadURL(filename: String, contentType: String) async throws -> TenxStorageUploadResponse? {
        guard let token = accessToken else { return nil }
        return try await storage.createUpload(
            bucket: "media",
            filename: filename,
            contentType: contentType,
            accessToken: token
        )
    }
}
