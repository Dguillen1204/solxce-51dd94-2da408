// Models/BackendSyncService.swift
import Foundation
import SwiftData
import SwiftUI

/// Codable payload for syncing workout records
private struct SyncWorkoutPayload: Codable {
    let id: String
    let title: String
    let bodyPartFocus: String
    let durationMinutes: Int
    let durationSeconds: Int
    let calories: Int
    let date: Double
    let totalVolumeLbs: Double
    let totalSets: Int
}

/// Codable payload for syncing profile data
private struct SyncProfilePayload: Codable {
    let id: String
    let name: String
    let handle: String
    let athleteType: String
    let updatedAt: Double
}

/// Manages syncing workout records, athlete profiles, and cloud storage
/// using the generated 10x backend clients (TenxAuth, BackendClient, TenxData, TenxStorage).
@MainActor
public final class BackendSyncService: ObservableObject {
    public static let shared = BackendSyncService()

    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUserId: String? = nil
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var lastSyncDate: Date? = nil
    @Published public private(set) var syncErrorMessage: String? = nil

    private let auth = TenxAuth()
    private let client = BackendClient()
    private let data = TenxData()
    private let storage = TenxStorage()

    private var accessToken: String?

    private init() {}

    // MARK: - Authentication

    public func signUp(email: String, password: String) async throws -> TenxAuthResponse {
        let response = try await auth.signUp(email: email, password: password)
        self.isAuthenticated = true
        self.currentUserId = response.user.id
        self.accessToken = response.accessToken
        return response
    }

    public func signIn(email: String, password: String) async throws -> TenxAuthResponse {
        let response = try await auth.signIn(email: email, password: password)
        self.isAuthenticated = true
        self.currentUserId = response.user.id
        self.accessToken = response.accessToken
        return response
    }

    public func signOut() async throws {
        if let token = accessToken {
            try? await auth.signOut(accessToken: token)
        }
        self.isAuthenticated = false
        self.currentUserId = nil
        self.accessToken = nil
    }

    // MARK: - Backend Client Endpoints

    /// Fetches system health and status from backend
    public func checkHealth() async -> Bool {
        do {
            let res = try await client.request(path: "/health")
            return !res.isEmpty
        } catch {
            return false
        }
    }

    /// Performs authenticated GET request to custom backend API endpoints
    public func fetchAthleteCloudStats() async throws -> [String: String]? {
        guard isAuthenticated, let token = accessToken else { return nil }
        let data = try await client.request(
            path: "/api/athlete/stats",
            method: "GET",
            accessToken: token
        )
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    /// Performs authenticated POST request to backend custom endpoint
    public func postTelemetryEvent(eventName: String, parameters: [String: String]) async throws -> Bool {
        guard isAuthenticated, let token = accessToken else { return false }
        var payload = parameters
        payload["eventName"] = eventName
        payload["timestamp"] = ISO8601DateFormatter().string(from: Date())
        let bodyData = try JSONEncoder().encode(payload)
        _ = try await client.request(
            path: "/api/telemetry",
            method: "POST",
            body: bodyData,
            accessToken: token
        )
        return true
    }

    // MARK: - SwiftData / Cloud Sync

    /// Records an individual workout event to backend cloud data
    @discardableResult
    public func recordWorkoutEvent(title: String, durationMinutes: Int, calories: Int) async throws -> Bool {
        guard isAuthenticated, let token = accessToken else { return false }
        let payload: [String: String] = [
            "title": title,
            "duration": String(durationMinutes),
            "calories": String(calories),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        _ = try await data.insert(table: "workout_logs", value: payload, accessToken: token)
        return true
    }

    /// Syncs local workouts with cloud database
    public func syncWorkouts(modelContext: ModelContext) async {
        guard isAuthenticated, let token = accessToken else { return }

        self.isSyncing = true
        self.syncErrorMessage = nil

        do {
            let descriptor = FetchDescriptor<WorkoutSession>()
            let workouts = try modelContext.fetch(descriptor)

            for session in workouts {
                let payload = SyncWorkoutPayload(
                    id: session.id.uuidString,
                    title: session.title,
                    bodyPartFocus: session.bodyPartFocus,
                    durationMinutes: session.durationMinutes,
                    durationSeconds: session.durationMinutes * 60,
                    calories: 0,
                    date: session.date.timeIntervalSince1970,
                    totalVolumeLbs: session.totalVolumeLbs,
                    totalSets: session.totalSets
                )

                _ = try await data.insert(table: "workout_sessions", value: payload, accessToken: token)
            }

            self.lastSyncDate = Date()
        } catch {
            self.syncErrorMessage = error.localizedDescription
        }

        self.isSyncing = false
    }

    /// Updates or pushes user profile data to backend
    public func syncProfileData(name: String, handle: String, athleteType: String) async {
        await syncProfile(name: name, handle: handle, athleteType: athleteType)
    }

    /// Updates or pushes user profile data to backend
    public func syncProfile(name: String, handle: String, athleteType: String) async {
        guard isAuthenticated, let token = accessToken, let userId = currentUserId else { return }

        do {
            let payload = SyncProfilePayload(
                id: userId,
                name: name,
                handle: handle,
                athleteType: athleteType,
                updatedAt: Date().timeIntervalSince1970
            )

            _ = try await data.insert(table: "profiles", value: payload, accessToken: token)
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

    /// Uploads an athlete profile photo or workout media data through TenxStorage
    public func uploadMediaData(_ data: Data, filename: String, contentType: String) async throws -> String? {
        guard let token = accessToken else { return nil }
        let object = try await storage.upload(
            data: data,
            bucket: "media",
            filename: filename,
            contentType: contentType,
            accessToken: token
        )
        return object.id
    }

    /// Requests a download authorization URL for a stored object
    public func getDownloadURL(objectID: String) async throws -> URL? {
        guard let token = accessToken else { return nil }
        let downloadResponse = try await storage.downloadURL(
            objectID: objectID,
            accessToken: token
        )
        return downloadResponse.download.url
    }
}
