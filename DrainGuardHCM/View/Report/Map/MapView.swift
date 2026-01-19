//
//  MapView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//
//
//import SwiftUI
//import MapKit
//
//struct MapView: View {
//    let hazards: [Drain]
//    
//    @StateObject private var locationManager = LocationManager()
//    @State private var position: MapCameraPosition = .automatic
//    @State private var selectedHazard: Drain?
//    @State private var hasCentredOnUser = false
//    
//    var body: some View {
//        ZStack{
//            Color("main").ignoresSafeArea()
//            VStack{
//                Spacer()
//                Text("Select the sewer you want to report").font(.custom("BubblerOne-Regular", size: 50)).multilineTextAlignment(.center)
//                Spacer()
//                Map(position: $position) {
//                    ForEach(hazards) { hazard in
//                        Annotation(hazard.title, coordinate: hazard.coordinate) {
//                            VStack {
//                                if selectedHazard?.id == hazard.id {
//                                    Text(hazard.title)
//                                        .padding(6)
//                                        .background(.white)
//                                        .cornerRadius(8)
//                                }
//                                
//                                Image("status")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 40)
//                                    .onTapGesture { selectedHazard = hazard }
//                            }
//                        }
//                    }
//                    
//                    if let userCoord = locationManager.userLocation {
//                        Annotation("You are here", coordinate: userCoord) {
//                            VStack(spacing: 4) {
//                                Image("mascot").resizable().scaledToFit().frame(width: 50)
//                                Text("You are here")
//                                    .font(.caption)
//                                    .padding(4)
//                                    .background(Color.main.opacity(0.9))
//                                    .cornerRadius(6)
//                            }
//                        }
//                    }
//                }
//                .onReceive(locationManager.$userLocation) { coord in
//                    guard let coord else { return }
//                    
//                    // Only move the camera once, so the user can zoom/pan freely.
//                    if !hasCentredOnUser {
//                        hasCentredOnUser = true
//                        position = .camera(
//                            MapCamera(centerCoordinate: coord, distance: 3000)
//                        )
//                    }
//                }
//            }
//        }
//    }
//}
//#Preview {
//    MapView(hazards: sampleHazards)
//}

import SwiftUI
import MapKit

/// Map tab - For viewing drains, flood risks, navigation, etc.
/// NOT for reporting (reporting starts from [+] button)
struct MapView: View {
    @StateObject private var drainService = DrainService()
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedHazard: Drain?
    @State private var hasCentredOnUser = false
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(drainService.drains) { hazard in
                    Annotation("", coordinate: hazard.coordinate) {
                        hazardPin(isSelected: selectedHazard?.id == hazard.id)
                            .onTapGesture { selectedHazard = hazard }
                    }
                }
                
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
            
            // Loading indicator
            if drainService.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Loading drains...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            topRightControls()
            
            if let hazard = selectedHazard {
                drainInfoCard(hazard)
            }
        }
        .onReceive(locationManager.$userLocation) { coord in
            guard let coord else { return }
            if !hasCentredOnUser {
                hasCentredOnUser = true
                centerOn(coord)
            }
        }
        .task {
            // Fetch drains when view appears
            await drainService.fetchDrains()
        }
        .onAppear {
            locationManager.startTracking()
        }
        .onDisappear {
            locationManager.stopTracking()
        }
    }
    
    private func centerOn(_ coord: CLLocationCoordinate2D) {
        position = .camera(MapCamera(centerCoordinate: coord, distance: 2600))
    }
    
    @ViewBuilder
    private func topRightControls() -> some View {
        VStack(spacing: 10) {
            Button {
                if let coord = locationManager.userLocation {
                    centerOn(coord)
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.trailing, 16)
        .padding(.top, 110)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    @ViewBuilder
    private func drainInfoCard(_ hazard: Drain) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hazard.title)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)
                    
                    if let address = hazard.address {
                        Text(address)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let district = hazard.district, let ward = hazard.ward {
                        Text("\(ward), \(district)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    selectedHazard = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            
            Button {
                centerOn(hazard.coordinate)
            } label: {
                Label("View on Map", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: selectedHazard?.id)
    }
    
    @ViewBuilder
    private func hazardPin(isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: isSelected ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .font(.system(size: isSelected ? 22 : 20, weight: .bold))
                .foregroundStyle(isSelected ? Color.orange : Color.red)
                .shadow(radius: 2)
            
            Text("Drain")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .opacity(isSelected ? 1 : 0.85)
        }
    }
}

#Preview {
    MapView()
}
