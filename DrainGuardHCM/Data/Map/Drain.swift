//
//  Drain.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 17/1/26.
//

import SwiftUI
import MapKit

struct Drain: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}

let sampleHazards: [Drain] = [
    Drain(title: "Drain 1",
           coordinate: CLLocationCoordinate2D(latitude: 10.728979, longitude: 106.696641)),
    Drain(title: "Drain 2",
           coordinate: CLLocationCoordinate2D(latitude: 10.728956, longitude: 106.696412))
]
