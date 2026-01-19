//
//  CameraModel.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import Foundation
import UIKit
import AVFoundation

class CameraModel: NSObject, ObservableObject {
    @Published var lastPhoto: UIImage? = nil
    @Published var cameraError: String?
    
    lazy var session: AVCaptureSession = {
        print("📷 Creating camera session...")
        return AVCaptureSession()
    }()
    
    lazy var output: AVCapturePhotoOutput = {
        print("📷 Creating photo output...")
        return AVCapturePhotoOutput()
    }()

    func capturePhoto() {
        print("📷 Capture photo requested")
        
        // Check if session is running
        guard session.isRunning else {
            print("⚠️ Camera session not running!")
            DispatchQueue.main.async {
                self.cameraError = "Camera not ready"
            }
            return
        }
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("⚠️ Photo capture failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.cameraError = error.localizedDescription
            }
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("⚠️ Could not convert photo data to image")
            DispatchQueue.main.async {
                self.cameraError = "Failed to process photo"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.lastPhoto = image
            self.cameraError = nil
            print("📸 Photo captured successfully")
        }
    }
}

