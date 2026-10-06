// Models/CameraCaptureService.swift
import Foundation
import AVFoundation
import SwiftUI
import Combine
import UIKit

final class CameraCaptureService: NSObject, ObservableObject {
    @Published var isSessionRunning: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var capturedImage: UIImage?
    @Published var isTorchOn: Bool = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var isCapturing: Bool = false
    @Published var errorMessage: String?

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "app.solxce.camera.sessionQueue")
    private var activeDelegates: [NSObject] = []

    override init() {
        super.init()
        checkPermissions()
    }

    func checkPermissions() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.permissionGranted = true
            self.permissionDenied = false
            self.isSessionRunning = true
        }
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
                self.permissionDenied = false
            }
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
            DispatchQueue.main.async {
                self.permissionGranted = false
                self.permissionDenied = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.permissionGranted = false
                self.permissionDenied = true
            }
        }
        #endif
    }

    func setupSession() {
        #if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }
            }

            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }

            self.captureSession.commitConfiguration()
            self.startRunning()
        }
        #endif
    }

    func startRunning() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.isSessionRunning = true
        }
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
        DispatchQueue.main.async {
            self.isSessionRunning = false
        }
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
                DispatchQueue.main.async { self.isTorchOn = false }
            } else {
                try device.setTorchModeOn(level: 1.0)
                DispatchQueue.main.async { self.isTorchOn = true }
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling torch: \(error)")
        }
    }

    func switchCamera() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.currentCameraPosition = (self.currentCameraPosition == .back) ? .front : .back
        }
        #else
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()

            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            let newPosition: AVCaptureDevice.Position = (self.currentCameraPosition == .back) ? .front : .back
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.videoDeviceInput = newInput
            } else if let currentInput = self.videoDeviceInput {
                self.captureSession.addInput(currentInput)
            }

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
        DispatchQueue.main.async {
            self.isCapturing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isCapturing = false
                let mockImage = self.generateMockMealImage()
                self.capturedImage = mockImage
                completion(mockImage)
            }
        }
        #else
        guard !isCapturing else { return }
        DispatchQueue.main.async { self.isCapturing = true }

        let settings = AVCapturePhotoSettings()
        let processor = PhotoProcessor { [weak self] image in
            DispatchQueue.main.async {
                self?.isCapturing = false
                self?.capturedImage = image
                completion(image)
            }
        }
        self.activeDelegates.append(processor)
        self.photoOutput.capturePhoto(with: settings, delegate: processor)
        #endif
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

final class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {
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
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
