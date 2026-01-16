//
//  MapView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//
import SwiftUI
import MapKit

struct Hazard: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}

let sampleHazards: [Hazard] = [
    Hazard(title: "Drain 1",
           coordinate: CLLocationCoordinate2D(latitude: 10.728979, longitude: 106.696641)),
    Hazard(title: "Drain 2",
           coordinate: CLLocationCoordinate2D(latitude: 10.728956, longitude: 106.696412))
]
import SwiftUI
import MapKit

struct MapView: View {
    let hazards: [Hazard]

    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedHazard: Hazard?

    var body: some View {
        Map(position: $position) {
            // Hazards
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
                            .onTapGesture {
                                withAnimation {
                                    selectedHazard = hazard
                                }
                            }
                    }
                }
            }

            // Real-time "You are here"
            if let userCoord = locationManager.userLocation {
                Annotation("You are here", coordinate: userCoord) {
                    VStack(spacing: 4) {
                        Image("mascot").resizable().scaledToFit()

                        Text("You are here")
                            .font(.caption)
                            .padding(4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(6)
                    }
                }
            }
        }
        // Move camera whenever user location updates
        .onReceive(locationManager.$userLocation) { coord in
            if let coord = coord {
                position = .camera(
                    MapCamera(centerCoordinate: coord, distance: 3000)
                )
            }
        }
    }
}

#Preview {
    MapView(hazards: sampleHazards)
}
