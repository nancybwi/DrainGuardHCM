//
//  Drain.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 17/1/26.
//

import SwiftUI
import MapKit
import FirebaseFirestore

/// Represents a drain/sewer location in the city
struct Drain: Codable, Identifiable, Hashable {
    // MARK: - Identity
    @DocumentID var id: String?
    
    // MARK: - Basic Info
    let title: String
    let latitude: Double
    let longitude: Double
    
    // MARK: - Additional Details
    /// District or ward where this drain is located
    let district: String?
    let ward: String?
    
    /// Street address or nearest landmark
    let address: String?
    
    /// Type of drain (e.g., "street", "storm", "combined")
    let drainType: String?
    
    /// When this drain was last maintained
    var lastMaintained: Date?
    
    /// Current condition rating (1-5, 5 = excellent)
    var conditionRating: Double?
    
    /// Number of reports filed for this drain
    var reportCount: Int?
    
    // MARK: - Computed Properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Hashable conformance
    static func == (lhs: Drain, rhs: Drain) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Firestore Conversion

extension Drain {
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        if let district = district { dict["district"] = district }
        if let ward = ward { dict["ward"] = ward }
        if let address = address { dict["address"] = address }
        if let type = drainType { dict["drainType"] = type }
        if let maintained = lastMaintained {
            dict["lastMaintained"] = Timestamp(date: maintained)
        }
        if let rating = conditionRating { dict["conditionRating"] = rating }
        if let count = reportCount { dict["reportCount"] = count }
        
        return dict
    }
}

// MARK: - Sample Data (for testing/preview only)

let sampleHazards: [Drain] = [
    Drain(
        id: "drain-1",
        title: "Drain near Nguyen Hue Walking Street",
        latitude: 10.728979,
        longitude: 106.696641,
        district: "District 1",
        ward: "Ben Nghe Ward",
        address: "Nguyen Hue St",
        drainType: "street",
        lastMaintained: Date().addingTimeInterval(-60*60*24*30), // 30 days ago
        conditionRating: 3.5,
        reportCount: 2
    ),
    Drain(
        id: "drain-2",
        title: "Drain at Le Loi Boulevard",
        latitude: 10.728956,
        longitude: 106.696412,
        district: "District 1",
        ward: "Ben Nghe Ward",
        address: "Le Loi Blvd",
        drainType: "storm",
        lastMaintained: Date().addingTimeInterval(-60*60*24*15), // 15 days ago
        conditionRating: 4.0,
        reportCount: 0
    )
]
