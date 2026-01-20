//
//  LocationIntelligenceService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import Foundation
import MapKit
import CoreLocation

class LocationIntelligenceService {
    
    // MARK: - Configuration
    
    private let schoolProximityThreshold: Double = 500 // meters
    private let hospitalProximityThreshold: Double = 500 // meters
    
    // Rush hour in Ho Chi Minh City: 5 PM - 7 PM
    private let rushHourStart = 17 // 5 PM
    private let rushHourEnd = 19 // 7 PM
    
    // MARK: - Analyze Location
    
    /// Analyze location for risk factors
    func analyzeLocation(
        latitude: Double,
        longitude: Double,
        timestamp: Date
    ) async -> LocationIntelligence {
        print("📍 [LOCATION] Analyzing location intelligence...")
        print("📍 [LOCATION] Coordinates: \(latitude), \(longitude)")
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Check rush hour
        let isRushHour = checkRushHour(timestamp: timestamp)
        print("📍 [LOCATION] Rush hour: \(isRushHour)")
        
        // Search for nearby POIs
        let (nearSchool, schoolDistance, nearHospital, hospitalDistance, pois) = await searchNearbyPOIs(coordinate: coordinate)
        
        let intelligence = LocationIntelligence(
            nearSchool: nearSchool,
            nearHospital: nearHospital,
            distanceToSchool: schoolDistance,
            distanceToHospital: hospitalDistance,
            submittedDuringRushHour: isRushHour,
            nearbyPOIs: pois
        )
        
        print("✅ [LOCATION] Analysis complete")
        print("   - Near school: \(nearSchool) (\(schoolDistance.map { String(format: "%.0fm", $0) } ?? "N/A"))")
        print("   - Near hospital: \(nearHospital) (\(hospitalDistance.map { String(format: "%.0fm", $0) } ?? "N/A"))")
        print("   - Rush hour: \(isRushHour)")
        print("   - Nearby POIs: \(pois.count)")
        
        return intelligence
    }
    
    // MARK: - Rush Hour Detection
    
    private func checkRushHour(timestamp: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        return hour >= rushHourStart && hour < rushHourEnd
    }
    
    // MARK: - POI Search
    
    private func searchNearbyPOIs(coordinate: CLLocationCoordinate2D) async -> (
        nearSchool: Bool,
        schoolDistance: Double?,
        nearHospital: Bool,
        hospitalDistance: Double?,
        pois: [String]
    ) {
        print("🔍 [POI] Searching for nearby points of interest...")
        
        var nearSchool = false
        var schoolDistance: Double? = nil
        var nearHospital = false
        var hospitalDistance: Double? = nil
        var allPOIs: [String] = []
        
        // Search for schools
        let schoolResults = await searchPOIs(
            coordinate: coordinate,
            category: .school,
            radius: schoolProximityThreshold
        )
        
        if let closestSchool = schoolResults.first {
            nearSchool = true
            schoolDistance = closestSchool.distance
            allPOIs.append("School: \(closestSchool.name) (\(Int(closestSchool.distance))m)")
            print("🏫 [POI] Found school: \(closestSchool.name) at \(Int(closestSchool.distance))m")
        }
        
        // Search for hospitals
        let hospitalResults = await searchPOIs(
            coordinate: coordinate,
            category: .hospital,
            radius: hospitalProximityThreshold
        )
        
        if let closestHospital = hospitalResults.first {
            nearHospital = true
            hospitalDistance = closestHospital.distance
            allPOIs.append("Hospital: \(closestHospital.name) (\(Int(closestHospital.distance))m)")
            print("🏥 [POI] Found hospital: \(closestHospital.name) at \(Int(closestHospital.distance))m")
        }
        
        // Also search for universities
        let universityResults = await searchPOIs(
            coordinate: coordinate,
            category: .university,
            radius: schoolProximityThreshold
        )
        
        if let closestUniversity = universityResults.first {
            nearSchool = true // Universities count as schools
            if schoolDistance == nil || closestUniversity.distance < schoolDistance! {
                schoolDistance = closestUniversity.distance
            }
            allPOIs.append("University: \(closestUniversity.name) (\(Int(closestUniversity.distance))m)")
            print("🎓 [POI] Found university: \(closestUniversity.name) at \(Int(closestUniversity.distance))m")
        }
        
        return (nearSchool, schoolDistance, nearHospital, hospitalDistance, allPOIs)
    }
    
    // MARK: - MapKit Search
    
    private func searchPOIs(
        coordinate: CLLocationCoordinate2D,
        category: MKPointOfInterestCategory,
        radius: Double
    ) async -> [(name: String, distance: Double)] {
        
        return await withCheckedContinuation { continuation in
            let request = MKLocalPointsOfInterestRequest(
                center: coordinate,
                radius: radius
            )
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])
            
            let search = MKLocalSearch(request: request)
            
            search.start { response, error in
                if let error = error {
                    print("⚠️ [POI] Search error for \(category.rawValue): \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let mapItems = response?.mapItems else {
                    continuation.resume(returning: [])
                    return
                }
                
                let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                let results = mapItems.compactMap { item -> (name: String, distance: Double)? in
                    guard let location = item.placemark.location else { return nil }
                    let distance = userLocation.distance(from: location)
                    return (name: item.name ?? "Unknown", distance: distance)
                }.sorted { $0.distance < $1.distance }
                
                continuation.resume(returning: results)
            }
        }
    }
    
    // MARK: - Calculate Distance
    
    /// Calculate distance between two coordinates in meters
    func calculateDistance(
        from coord1: CLLocationCoordinate2D,
        to coord2: CLLocationCoordinate2D
    ) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
}
