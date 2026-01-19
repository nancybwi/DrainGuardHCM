//
//  DrainService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import FirebaseFirestore

@MainActor
class DrainService: ObservableObject {
    
    private let db = Firestore.firestore()
    
    @Published var drains: [Drain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch All Drains
    
    func fetchDrains() async {
        isLoading = true
        errorMessage = nil
        
        print("\n🗺️ [DRAINS] Fetching drains from Firestore...")
        
        do {
            let snapshot = try await db.collection("drains").getDocuments()
            
            let fetchedDrains = snapshot.documents.compactMap { doc -> Drain? in
                try? doc.data(as: Drain.self)
            }
            
            drains = fetchedDrains
            
            print("✅ [DRAINS] Fetched \(drains.count) drains")
            isLoading = false
            
        } catch {
            print("❌ [DRAINS] Failed to fetch drains")
            print("   Error: \(error.localizedDescription)")
            
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Fetch Nearby Drains
    
    func fetchNearbyDrains(latitude: Double, longitude: Double, radiusKm: Double = 5.0) async {
        isLoading = true
        errorMessage = nil
        
        print("\n🗺️ [DRAINS] Fetching drains near (\(latitude), \(longitude))...")
        
        // Simple approach: fetch all and filter by distance
        // For production, use GeoHash or similar for better performance
        
        do {
            let snapshot = try await db.collection("drains").getDocuments()
            
            let fetchedDrains = snapshot.documents.compactMap { doc -> Drain? in
                guard let drain = try? doc.data(as: Drain.self) else { return nil }
                
                // Calculate distance
                let distance = calculateDistance(
                    from: (latitude, longitude),
                    to: (drain.latitude, drain.longitude)
                )
                
                return distance <= radiusKm ? drain : nil
            }
            
            drains = fetchedDrains
            
            print("✅ [DRAINS] Found \(drains.count) drains within \(radiusKm)km")
            isLoading = false
            
        } catch {
            print("❌ [DRAINS] Failed to fetch nearby drains")
            print("   Error: \(error.localizedDescription)")
            
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Helper: Calculate Distance
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        let earthRadiusKm = 6371.0
        
        let lat1Rad = from.0 * .pi / 180
        let lat2Rad = to.0 * .pi / 180
        let deltaLat = (to.0 - from.0) * .pi / 180
        let deltaLon = (to.1 - from.1) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadiusKm * c
    }
}
