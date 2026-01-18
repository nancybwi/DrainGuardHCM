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
    let session = AVCaptureSession()           // removed fileprivate
    let output = AVCapturePhotoOutput()        // removed fileprivate

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.lastPhoto = image
        }
    }
}
