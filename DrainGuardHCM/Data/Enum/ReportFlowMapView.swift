//
//  ReportFlowMapView.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import SwiftUI
import MapKit

/// Second step in report flow: Select which drain to report
struct ReportFlowMapView: View {
    let capturedImage: UIImage
    
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDrain: Drain?
    @State private var hasCenteredOnUser = false
    @State private var showConfirmation = false
    @State private var proceedToSubmit = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Map
            Map(position: $position) {
                // Drain markers
                ForEach(sampleHazards) { drain in
                    Annotation("", coordinate: drain.coordinate) {
                        drainPin(drain: drain, isSelected: selectedDrain?.id == drain.id)
                            .onTapGesture {
                                selectedDrain = drain
                                showConfirmation = true
                            }
                    }
                }
                
                // User location
                if let userCoord = locationManager.userLocation {
                    Annotation("You are here", coordinate: userCoord) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 14, height: 14)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 14, height: 14)
                            }
                            
                            Text("You are here")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            // Top Instructions
            VStack {
                instructionCard()
                Spacer()
            }
            
            // Bottom: Recenter button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if let coord = locationManager.userLocation {
                            centerOn(coord)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding()
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Step 2: Select Drain")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .onReceive(locationManager.$userLocation) { coord in
            guard let coord else { return }
            if !hasCenteredOnUser {
                hasCenteredOnUser = true
                centerOn(coord)
            }
        }
        .onAppear {
            // Start location tracking when map appears
            print("🗺️ Map view appeared - starting location tracking")
            locationManager.startTracking()
        }
        .onDisappear {
            // Stop location tracking when map disappears
            print("🗺️ Map view disappeared - stopping location tracking")
            locationManager.stopTracking()
        }
        .confirmationDialog(
            "Confirm Drain Selection",
            isPresented: $showConfirmation,
            presenting: selectedDrain
        ) { drain in
            Button("Proceed with \(drain.title)") {
                proceedToSubmit = true
            }
            Button("Cancel", role: .cancel) {
                selectedDrain = nil
            }
        } message: { drain in
            Text("You selected:\n\(drain.title)\n\n\(drain.address ?? "")\n\nProceed to submit report?")
        }
        .navigationDestination(isPresented: $proceedToSubmit) {
            if let drain = selectedDrain {
                ReportSubmitView(image: capturedImage, selectedDrain: drain)
            }
        }
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func instructionCard() -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(.blue)
                Text("Tap on the drain you want to report")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            
            // Small preview of captured image
            HStack {
                Text("Photo captured:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .padding()
    }
    
    @ViewBuilder
    private func drainPin(drain: Drain, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: isSelected ? "drop.triangle.fill" : "drop.triangle")
                .font(.system(size: isSelected ? 26 : 22, weight: .bold))
                .foregroundStyle(isSelected ? Color.blue : Color.orange)
                .shadow(radius: 3)
            
            if isSelected {
                Text(drain.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func centerOn(_ coord: CLLocationCoordinate2D) {
        position = .camera(MapCamera(centerCoordinate: coord, distance: 1500))
    }
}

#Preview {
    NavigationStack {
        ReportFlowMapView(capturedImage: MockImageFactory.make())
    }
}
