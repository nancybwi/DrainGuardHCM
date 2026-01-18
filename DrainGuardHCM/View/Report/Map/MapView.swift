//
//  MapView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI
import MapKit

struct MapView: View {
    let hazards: [Drain]
    
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedHazard: Drain?
    @State private var hasCentredOnUser = false
    
    var body: some View {
        ZStack{
            Color("main").ignoresSafeArea()
            VStack{
                Spacer()
                Text("Select the sewer you want to report").font(.custom("BubblerOne-Regular", size: 50)).multilineTextAlignment(.center)
                Spacer()
                Map(position: $position) {
                    ForEach(hazards) { hazard in
                        Annotation(hazard.title, coordinate: hazard.coordinate) {
                            VStack {
                                if selectedHazard?.id == hazard.id {
                                    Text(hazard.title)
                                        .padding(6)
                                        .background(.white)
                                        .cornerRadius(8)
                                }
                                
                                Image("status")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                    .onTapGesture { selectedHazard = hazard }
                            }
                        }
                    }
                    
                    if let userCoord = locationManager.userLocation {
                        Annotation("You are here", coordinate: userCoord) {
                            VStack(spacing: 4) {
                                Image("mascot").resizable().scaledToFit().frame(width: 50)
                                Text("You are here")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.main.opacity(0.9))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .onReceive(locationManager.$userLocation) { coord in
                    guard let coord else { return }
                    
                    // Only move the camera once, so the user can zoom/pan freely.
                    if !hasCentredOnUser {
                        hasCentredOnUser = true
                        position = .camera(
                            MapCamera(centerCoordinate: coord, distance: 3000)
                        )
                    }
                }
            }
        }
    }
}
#Preview {
    MapView(hazards: sampleHazards)
}
