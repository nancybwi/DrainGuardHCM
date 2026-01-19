//
//  CameraView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct CameraView: View {
    let selectedDrain: Drain
    
    @State private var capturedImage: UIImage? = nil
    @StateObject private var cameraModel = CameraModel()
    @State private var goSubmit = false
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            VStack {
                Text("Capture the drain you want to report")
                    .font(.custom("BubblerOne-Regular", size: 30))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Camera(cameraModel: cameraModel)
                    .frame(width: 300, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                    )
                
                Spacer()
                
                // Selected Drain Info
                VStack(spacing: 4) {
                    Text("📍 \(selectedDrain.title)")
                        .font(.system(size: 16, weight: .semibold))
                    if let address = selectedDrain.address {
                        Text(address)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                Button {
                    cameraModel.capturePhoto()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture Photo")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                }
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(Capsule())
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(cameraModel.$lastPhoto) { img in
            guard let img else { return }
            capturedImage = img
            goSubmit = true
        }
        .navigationDestination(isPresented: $goSubmit) {
            if let img = capturedImage {
                ReportSubmitView(image: img, selectedDrain: selectedDrain)
            } else {
                Text("No image captured")
            }
        }
    }
}

#Preview {
    NavigationStack {
        CameraView(selectedDrain: sampleHazards[0])
    }
}
