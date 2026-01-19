//
//  ReportFlowCameraView.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import SwiftUI

/// First step in report flow: Capture photo
struct ReportFlowCameraView: View {
    @State private var capturedImage: UIImage? = nil
    @StateObject private var cameraModel = CameraModel()
    @State private var goToMapSelection = false
    @State private var isCameraReady = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Step 1: Take Photo")
                        .font(.custom("BubblerOne-Regular", size: 32))
                    
                    Text("Capture the drain issue you want to report")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Camera Preview - Only shown when ready
                if isCameraReady {
                    Camera(cameraModel: cameraModel)
                        .frame(width: 320, height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(radius: 10)
                } else {
                    // Loading placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 320, height: 420)
                        
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text("Initializing camera...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                // Buttons
                HStack(spacing: 16) {
                    // Cancel
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    
                    // Capture
                    Button {
                        cameraModel.capturePhoto()
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Capture Photo")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .disabled(!isCameraReady)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Initialize camera when view appears
            print("📷 Camera view appeared - initializing...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCameraReady = true
            }
        }
        .onDisappear {
            // Clean up camera when view disappears
            print("📷 Camera view disappeared - cleaning up")
            isCameraReady = false
        }
        .onReceive(cameraModel.$lastPhoto) { img in
            guard let img else { return }
            capturedImage = img
            goToMapSelection = true
        }
        .navigationDestination(isPresented: $goToMapSelection) {
            if let img = capturedImage {
                ReportFlowMapView(capturedImage: img)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportFlowCameraView()
    }
}
