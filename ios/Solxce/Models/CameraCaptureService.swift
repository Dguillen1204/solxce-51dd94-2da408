// Models/CameraCaptureService.swift
import Foundation
import AVFoundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class CameraCaptureService: NSObject, ObservableObject {
    @Published var isSessionRunning: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var isSimulator: Bool = false
    @Published var capturedImage: UIImage?
    @Published var isTorchOn: Bool = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var isCapturing: Bool = false
    @Published var errorMessage: String?

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "app.solxce.camera.sessionQueue")

    override init() {
        super.init()
        #if targetEnvironment(simulator)
        self.isSimulator = true
        self.permissionGranted = true
        #else
        checkPermissions()
        #endif
    }

    func checkPermissions() {
        #if targetEnvironment(simulator)
        self.isSimulator = true
        self.permissionGranted = true
        return
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            self.permissionDenied = false
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    self?.permissionDenied = !granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        case .denied, .restricted:
            self.permissionGranted = false
            self.permissionDenied = true
        @unknown default:
            self.permissionGranted = false
            self.permissionDenied = true
        }
        #endif
    }

    func setupSession() {
        #if targetEnvironment(simulator)
        return
        #else
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // Setup input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to access back camera device"
                }
                self.captureSession.commitConfiguration()
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }

                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                }

                self.captureSession.commitConfiguration()
                self.startRunning()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to initialize camera input: \(error.localizedDescription)"
                }
                self.captureSession.commitConfiguration()
            }
        }
        #endif
    }

    func startRunning() {
        #if targetEnvironment(simulator)
        isSessionRunning = true
        #else
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
        #endif
    }

    func stopRunning() {
        #if targetEnvironment(simulator)
        isSessionRunning = false
        #else
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
        #endif
    }

    func toggleTorch() {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling torch: \(error)")
        }
    }

    func switchCamera() {
        #if targetEnvironment(simulator)
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        #else
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()

            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            let newPosition: AVCaptureDevice.Position = (self.currentCameraPosition == .back) ? .front : .back
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice),
                  self.captureSession.canAddInput(newInput) else {
                // Re-add previous
                if let currentInput = self.videoDeviceInput {
                    self.captureSession.addInput(currentInput)
                }
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.addInput(newInput)
            self.videoDeviceInput = newInput
            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.currentCameraPosition = newPosition
                self.isTorchOn = false
            }
        }
        #endif
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        #if targetEnvironment(simulator)
        // Simulator fallback image
        self.isCapturing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isCapturing = false
            let mockImage = self.generateMockMealImage()
            self.capturedImage = mockImage
            completion(mockImage)
        }
        #else
        guard !isCapturing else { return }
        isCapturing = true

        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureProcessor { [weak self] image in
            DispatchQueue.main.async {
                self?.isCapturing = false
                self?.capturedImage = image
                completion(image)
            }
        }
        self.photoCaptureDelegates[settings.uniqueID] = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
        #endif
    }

    private var photoCaptureDelegates: [Int64: PhotoCaptureProcessor] = [:]

    private func generateMockMealImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Background gradient
            let colors = [UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1.0).cgColor, UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0).cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])

            // Bowl shape
            context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.22, blue: 0.28, alpha: 1.0).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 40, y: 40, width: 320, height: 320))

            // Food items
            context.cgContext.setFillColor(UIColor(red: 0.85, green: 0.55, blue: 0.2, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 90, y: 100, width: 110, height: 110)) // Protein

            context.cgContext.setFillColor(UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 200, y: 110, width: 100, height: 100)) // Rice/Carb

            context.cgContext.setFillColor(UIColor(red: 0.2, green: 0.75, blue: 0.4, alpha: 0.9).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 130, y: 200, width: 130, height: 90)) // Veggie/Broccoli
        }
    }
}

final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        completion(image)
    }
}

// MARK: - Live Camera Viewfinder Layer
struct LiveCameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraCaptureService

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = cameraService.captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = cameraService.captureSession
    }
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
