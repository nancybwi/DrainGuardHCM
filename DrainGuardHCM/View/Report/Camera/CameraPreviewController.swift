//
//  CameraPreviewController.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//
import UIKit
import AVFoundation

class CameraPreviewController: UIViewController {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var cameraModel: CameraModel?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func configure(with model: CameraModel) {
        self.cameraModel = model
        setupSession()
    }

    private func setupSession() {
        guard let model = cameraModel else { return }
        let session = model.session
        session.beginConfiguration()
        session.sessionPreset = .photo

        // input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            print("Cannot access camera")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // output
        if session.canAddOutput(model.output) {
            session.addOutput(model.output)
        }

        session.commitConfiguration()

        // preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        if !session.isRunning {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraModel?.session.stopRunning()    }
}
