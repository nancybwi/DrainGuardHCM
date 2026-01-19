//
//  CameraPreviewController.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//
import UIKit
import AVFoundation

class CameraPreviewController: UIViewController {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var cameraModel: CameraModel?
    private let sessionQueue = DispatchQueue(label: "com.drainguard.camera.session")
    private var isSetup = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func configure(with model: CameraModel) {
        print("📷 Configuring camera controller...")
        self.cameraModel = model
        checkPermissionsAndSetup()
    }
    
    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("📷 Camera authorized")
            setupSession()
            
        case .notDetermined:
            print("📷 Requesting camera permission...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    print("📷 Camera permission granted")
                    self?.setupSession()
                } else {
                    print("⚠️ Camera permission denied")
                    self?.showPermissionError()
                }
            }
            
        case .denied, .restricted:
            print("⚠️ Camera access denied or restricted")
            showPermissionError()
            
        @unknown default:
            print("⚠️ Unknown camera authorization status")
            showPermissionError()
        }
    }
    
    private func showPermissionError() {
        DispatchQueue.main.async {
            let label = UILabel()
            label.text = "Camera access required.\nEnable in Settings."
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .white
            label.frame = self.view.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(label)
        }
    }

    private func setupSession() {
        guard !isSetup, let model = cameraModel else {
            print("📷 Setup already done or no model")
            return
        }
        
        isSetup = true
        print("📷 Setting up camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = model.session
            session.beginConfiguration()
            
            // Set preset before adding inputs
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }

            // Get camera device
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
                print("⚠️ Cannot find back camera")
                session.commitConfiguration()
                return
            }
            
            // Create input
            guard let input = try? AVCaptureDeviceInput(device: camera) else {
                print("⚠️ Cannot create camera input")
                session.commitConfiguration()
                return
            }
            
            // Add input
            guard session.canAddInput(input) else {
                print("⚠️ Cannot add camera input to session")
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            print("📷 Camera input added")

            // Add output
            if session.canAddOutput(model.output) {
                session.addOutput(model.output)
                print("📷 Photo output added")
            } else {
                print("⚠️ Cannot add photo output")
            }

            session.commitConfiguration()
            print("📷 Session configuration committed")

            // Setup preview layer on main thread
            DispatchQueue.main.async {
                self.setupPreviewLayer(session: session)
            }

            // Start session
            if !session.isRunning {
                print("📷 Starting camera session...")
                session.startRunning()
                print("📷 Camera session running: \(session.isRunning)")
            }
        }
    }
    
    private func setupPreviewLayer(session: AVCaptureSession) {
        print("📷 Setting up preview layer...")
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
            print("📷 Preview layer added")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📷 Camera view appeared")
        
        sessionQueue.async { [weak self] in
            guard let session = self?.cameraModel?.session else { return }
            if !session.isRunning {
                print("📷 Starting session in viewDidAppear")
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("📷 Camera view will disappear")
        
        sessionQueue.async { [weak self] in
            guard let session = self?.cameraModel?.session else { return }
            if session.isRunning {
                print("📷 Stopping camera session")
                session.stopRunning()
            }
        }
    }
    
    deinit {
        print("📷 CameraPreviewController deinitialized")
        sessionQueue.async { [weak cameraModel] in
            if let session = cameraModel?.session, session.isRunning {
                session.stopRunning()
            }
        }
    }
}

