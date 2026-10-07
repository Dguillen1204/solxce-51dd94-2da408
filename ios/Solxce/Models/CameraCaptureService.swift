// Models/CameraCaptureService.swift
import Foundation
import SwiftUI
import Combine
import UIKit

/// In-memory camera simulation and photo processor.
/// Completely free of AVCaptureSession / AVCaptureDevice hardware calls and sensitive camera permissions.
final class CameraCaptureService: NSObject, ObservableObject {
    @Published var isSessionRunning: Bool = true
    @Published var permissionGranted: Bool = true
    @Published var permissionDenied: Bool = false
    @Published var capturedImage: UIImage?
    @Published var isTorchOn: Bool = false
    @Published var isCapturing: Bool = false
    @Published var errorMessage: String?

    override init() {
        super.init()
    }

    func checkPermissions() {
        DispatchQueue.main.async {
            self.permissionGranted = true
            self.permissionDenied = false
            self.isSessionRunning = true
        }
    }

    func setupSession() {}

    func startRunning() {
        DispatchQueue.main.async {
            self.isSessionRunning = true
        }
    }

    func stopRunning() {
        DispatchQueue.main.async {
            self.isSessionRunning = false
        }
    }

    func toggleTorch() {
        DispatchQueue.main.async {
            self.isTorchOn.toggle()
        }
    }

    func switchCamera() {}

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.main.async {
            self.isCapturing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isCapturing = false
                let mockImage = self.generateMockMealImage()
                self.capturedImage = mockImage
                completion(mockImage)
            }
        }
    }

    private func generateMockMealImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let colors = [UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1.0).cgColor, UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0).cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) {
                context.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }

            context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.22, blue: 0.28, alpha: 1.0).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 40, y: 40, width: 320, height: 320))

            context.cgContext.setFillColor(UIColor(red: 0.85, green: 0.55, blue: 0.2, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 90, y: 100, width: 110, height: 110))

            context.cgContext.setFillColor(UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 200, y: 110, width: 100, height: 100))

            context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.75, blue: 0.4, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 130, y: 200, width: 130, height: 90))
        }
    }
}

// MARK: - Safe Camera Viewfinder View
struct LiveCameraPreviewView: View {
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                Text("AI Visual Scanner Ready")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
