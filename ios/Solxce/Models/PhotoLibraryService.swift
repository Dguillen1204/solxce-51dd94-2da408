// Models/PhotoLibraryService.swift
import Foundation
import Photos
import UIKit

/// Service governing photo library authorization, permission status, and direct asset saving
@MainActor
final class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    init() {
        refreshStatus()
    }

    /// Refresh the current authorization status
    func refreshStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.authorizationStatus = status
    }

    /// Explicitly request permission to access the user's photo library
    func requestPermission() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .authorized || current == .limited {
            self.authorizationStatus = current
            return true
        }

        if current == .denied || current == .restricted {
            self.authorizationStatus = current
            return false
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authorizationStatus = newStatus
        return newStatus == .authorized || newStatus == .limited
    }

    /// Request permission specifically for adding photos/graphics to the library
    func requestAddOnlyPermission() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .authorized || current == .limited {
            return true
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    /// Save an image to the user's Photo Library after requesting permission
    func saveImageToPhotoLibrary(_ image: UIImage) async -> Bool {
        let granted = await requestAddOnlyPermission()
        guard granted else { return false }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, _ in
                DispatchQueue.main.async {
                    continuation.resume(returning: success)
                }
            })
        }
    }
}
