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

    // MARK: - SwiftData / Cloud Sync

    /// Records an individual workout event to backend cloud data
    @discardableResult
    public func recordWorkoutEvent(title: String, durationMinutes: Int, calories: Int) async throws -> Bool {
        guard isAuthenticated, let token = accessToken else { return false }
        let payload = SyncWorkoutPayload(
            id: UUID().uuidString,
            title: title,
            bodyPartFocus: "Full Body",
            durationMinutes: durationMinutes,
            durationSeconds: durationMinutes * 60,
            calories: calories,
            date: Date().timeIntervalSince1970,
            totalVolumeLbs: 0,
            totalSets: 0
        )
        _ = try await data.insert(table: "workouts", value: payload, accessToken: token)
        return true
    }

    /// Syncs local workout logs to the backend cloud data store
    public func syncWorkouts(from context: ModelContext) async {
        guard isAuthenticated, let token = accessToken else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let descriptor = FetchDescriptor<WorkoutSession>()
            let localWorkouts = try context.fetch(descriptor)

            for session in localWorkouts {
                let payload = SyncWorkoutPayload(
                    id: session.id.uuidString,
                    title: session.title,
                    bodyPartFocus: session.bodyPartFocus,
                    durationMinutes: session.durationMinutes,
                    durationSeconds: session.durationMinutes * 60,
                    calories: Int(Double(session.durationMinutes) * 7.5),
                    date: session.date.timeIntervalSince1970,
                    totalVolumeLbs: session.totalVolumeLbs,
                    totalSets: session.totalSets
                )

                _ = try await data.insert(table: "workouts", value: payload, accessToken: token)
            }

            self.lastSyncDate = Date()
            self.syncErrorMessage = nil
        } catch {
            self.syncErrorMessage = error.localizedDescription
        }
    }

    /// Syncs profile metadata to the backend
    public func syncProfileData(name: String, handle: String, athleteType: String) async {
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
        guard let uploadResponse = try await requestMediaUploadURL(filename: filename, contentType: contentType) else {
            return nil
        }

        var request = URLRequest(url: uploadResponse.upload.url)
        request.httpMethod = uploadResponse.upload.method
        for (headerField, headerValue) in uploadResponse.upload.headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
            return uploadResponse.object.path
        }
        return nil
    }

    /// Requests a download authorization URL for a stored object
    public func getDownloadURL(path: String) async throws -> URL? {
        guard let token = accessToken else { return nil }
        let downloadResponse = try await storage.createDownload(
            bucket: "media",
            path: path,
            accessToken: token
        )
        return downloadResponse.download.url
    }
}
