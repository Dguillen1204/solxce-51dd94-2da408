// Models/BackendSyncService.swift
import Foundation
import SwiftData
import SwiftUI

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

    private var accessToken: String? {
        auth.session?.accessToken
    }

    private init() {
        self.isAuthenticated = auth.session != nil
        self.currentUserId = auth.session?.user.id
    }

    // MARK: - Authentication

    public func signUp(email: String, password: String) async throws -> TenxAuthSession {
        let session = try await auth.signUp(email: email, password: password)
        self.isAuthenticated = true
        self.currentUserId = session.user.id
        return session
    }

    public func signIn(email: String, password: String) async throws -> TenxAuthSession {
        let session = try await auth.signIn(email: email, password: password)
        self.isAuthenticated = true
        self.currentUserId = session.user.id
        return session
    }

    public func signOut() async throws {
        try await auth.signOut()
        self.isAuthenticated = false
        self.currentUserId = nil
    }

    // MARK: - Backend Client Endpoints

    /// Fetches system health and status from backend
    public func checkHealth() async -> Bool {
        do {
            let res = try await client.health()
            return res.status == "ok"
        } catch {
            return false
        }
    }

    // MARK: - SwiftData / Cloud Sync

    /// Syncs local workout logs to the backend cloud data store
    public func syncWorkouts(from context: ModelContext) async {
        guard isAuthenticated, let token = accessToken else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let descriptor = FetchDescriptor<WorkoutSession>()
            let localWorkouts = try context.fetch(descriptor)

            for session in localWorkouts {
                let workoutDoc: [String: AnyCodable] = [
                    "title": AnyCodable(session.title),
                    "sportType": AnyCodable(session.sportType.rawValue),
                    "durationSeconds": AnyCodable(session.durationSeconds),
                    "calories": AnyCodable(session.calories),
                    "date": AnyCodable(session.date.timeIntervalSince1970),
                    "isCompleted": AnyCodable(session.isCompleted),
                    "avgHeartRate": AnyCodable(session.avgHeartRate ?? 0),
                    "distanceMeters": AnyCodable(session.distanceMeters ?? 0)
                ]

                _ = try await data.upsertDocument(
                    collection: "workouts",
                    id: session.id.uuidString,
                    data: workoutDoc,
                    accessToken: token
                )
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
            let profileDoc: [String: AnyCodable] = [
                "name": AnyCodable(name),
                "handle": AnyCodable(handle),
                "athleteType": AnyCodable(athleteType),
                "updatedAt": AnyCodable(Date().timeIntervalSince1970)
            ]

            _ = try await data.upsertDocument(
                collection: "profiles",
                id: userId,
                data: profileDoc,
                accessToken: token
            )
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
