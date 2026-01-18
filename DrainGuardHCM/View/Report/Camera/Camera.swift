//
//  Camera.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI
import UIKit
import Foundation


struct Camera: UIViewControllerRepresentable {
    @ObservedObject var cameraModel: CameraModel

    func makeUIViewController(context: Context) -> CameraPreviewController {
        let controller = CameraPreviewController()
        controller.configure(with: cameraModel)
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraPreviewController,
                                context: Context) {}
}
