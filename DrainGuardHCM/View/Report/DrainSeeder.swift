//
//  DrainSeeder.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import FirebaseFirestore

/// Service to seed the drains collection in Firestore
class DrainSeeder {
    
    private let db = Firestore.firestore()
    
    // MARK: - Seed Drains Collection
    
    func seedDrains() async throws {
        print("\n🌱━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌱 [SEEDER] Starting drain collection seeding")
        print("🌱━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        let drains = createSampleDrains()
        print("🌱 [SEEDER] Created \(drains.count) sample drains")
        
        var successCount = 0
        var failCount = 0
        
        for drain in drains {
            do {
                let docRef = try await db.collection("drains").addDocument(data: drain.toDictionary())
                print("✅ [SEEDER] Saved drain: \(drain.title) (ID: \(docRef.documentID))")
                successCount += 1
            } catch {
                print("❌ [SEEDER] Failed to save drain: \(drain.title)")
                print("   Error: \(error.localizedDescription)")
                failCount += 1
            }
        }
        
        print("\n🌱━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌱 [SEEDER] Seeding complete!")
        print("🌱 [SEEDER] Success: \(successCount), Failed: \(failCount)")
        print("🌱━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    // MARK: - Check if Collection Exists
    
    func checkDrainsExist() async throws -> Bool {
        let snapshot = try await db.collection("drains").limit(to: 1).getDocuments()
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Clear Collection (for testing)
    
    func clearDrains() async throws {
        print("\n🗑️ [SEEDER] Clearing drains collection...")
        
        let snapshot = try await db.collection("drains").getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
            print("🗑️ [SEEDER] Deleted drain: \(document.documentID)")
        }
        
        print("🗑️ [SEEDER] Cleared \(snapshot.documents.count) drains\n")
    }
    
    // MARK: - Sample Drain Data
    
    private func createSampleDrains() -> [Drain] {
        return [
            // District 1 - Downtown Ho Chi Minh City
            Drain(
                id: nil,
                title: "Nguyen Hue Walking Street - North End",
                latitude: 10.774520,
                longitude: 106.702347,
                district: "District 1",
                ward: "Ben Nghe Ward",
                address: "Nguyen Hue St, near Opera House",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*30), // 30 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Nguyen Hue Walking Street - South End",
                latitude: 10.772893,
                longitude: 106.704238,
                district: "District 1",
                ward: "Ben Nghe Ward",
                address: "Nguyen Hue St, near Bach Dang Wharf",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*20), // 20 days ago
                conditionRating: 4.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Le Loi Boulevard - Pasteur Intersection",
                latitude: 10.774129,
                longitude: 106.695915,
                district: "District 1",
                ward: "Ben Nghe Ward",
                address: "Le Loi Blvd & Pasteur St",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*45), // 45 days ago
                conditionRating: 3.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Ben Thanh Market - Main Entrance",
                latitude: 10.772515,
                longitude: 106.698128,
                district: "District 1",
                ward: "Ben Thanh Ward",
                address: "Le Loi St, Ben Thanh Market",
                drainType: "combined",
                lastMaintained: Date().addingTimeInterval(-60*60*24*15), // 15 days ago
                conditionRating: 4.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Nguyen Trai Street - District 1",
                latitude: 10.768562,
                longitude: 106.687841,
                district: "District 1",
                ward: "Nguyen Cu Trinh Ward",
                address: "Nguyen Trai St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*60), // 60 days ago
                conditionRating: 2.5,
                reportCount: 0
            ),
            
            // District 3
            Drain(
                id: nil,
                title: "Vo Van Tan Street - District 3",
                latitude: 10.783847,
                longitude: 106.686752,
                district: "District 3",
                ward: "Ward 6",
                address: "Vo Van Tan St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*50), // 50 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Hai Ba Trung Street - District 3",
                latitude: 10.779513,
                longitude: 106.691247,
                district: "District 3",
                ward: "Ward 8",
                address: "Hai Ba Trung St",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*25), // 25 days ago
                conditionRating: 4.0,
                reportCount: 0
            ),
            
            // District 5 - Cho Lon
            Drain(
                id: nil,
                title: "Tran Hung Dao Boulevard - District 5",
                latitude: 10.752614,
                longitude: 106.672836,
                district: "District 5",
                ward: "Ward 11",
                address: "Tran Hung Dao Blvd",
                drainType: "combined",
                lastMaintained: Date().addingTimeInterval(-60*60*24*40), // 40 days ago
                conditionRating: 3.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Nguyen Chi Thanh Street - District 5",
                latitude: 10.755823,
                longitude: 106.665432,
                district: "District 5",
                ward: "Ward 9",
                address: "Nguyen Chi Thanh St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*35), // 35 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            // District 7 - Phu My Hung
            Drain(
                id: nil,
                title: "Nguyen Van Linh Boulevard - District 7",
                latitude: 10.729847,
                longitude: 106.719562,
                district: "District 7",
                ward: "Tan Phong Ward",
                address: "Nguyen Van Linh Blvd, Phu My Hung",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*10), // 10 days ago
                conditionRating: 4.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Crescent Mall Area - District 7",
                latitude: 10.730547,
                longitude: 106.717834,
                district: "District 7",
                ward: "Tan Phu Ward",
                address: "Ton Dat Tien St, Crescent Mall",
                drainType: "combined",
                lastMaintained: Date().addingTimeInterval(-60*60*24*20), // 20 days ago
                conditionRating: 4.0,
                reportCount: 0
            ),
            
            // Binh Thanh District
            Drain(
                id: nil,
                title: "Xo Viet Nghe Tinh Street - Binh Thanh",
                latitude: 10.803452,
                longitude: 106.701834,
                district: "Binh Thanh District",
                ward: "Ward 21",
                address: "Xo Viet Nghe Tinh St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*55), // 55 days ago
                conditionRating: 2.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Dien Bien Phu Street - Binh Thanh",
                latitude: 10.797623,
                longitude: 106.692847,
                district: "Binh Thanh District",
                ward: "Ward 25",
                address: "Dien Bien Phu St",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*30), // 30 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            // Phu Nhuan District
            Drain(
                id: nil,
                title: "Phan Dang Luu Street - Phu Nhuan",
                latitude: 10.799234,
                longitude: 106.677956,
                district: "Phu Nhuan District",
                ward: "Ward 7",
                address: "Phan Dang Luu St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*42), // 42 days ago
                conditionRating: 3.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Hoang Van Thu Street - Phu Nhuan",
                latitude: 10.802451,
                longitude: 106.673524,
                district: "Phu Nhuan District",
                ward: "Ward 9",
                address: "Hoang Van Thu St",
                drainType: "combined",
                lastMaintained: Date().addingTimeInterval(-60*60*24*28), // 28 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            // District 2 (Thu Duc City)
            Drain(
                id: nil,
                title: "Hanoi Highway - District 2",
                latitude: 10.797652,
                longitude: 106.733241,
                district: "District 2",
                ward: "Thao Dien Ward",
                address: "Hanoi Highway",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*18), // 18 days ago
                conditionRating: 4.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Thao Dien Area - District 2",
                latitude: 10.804523,
                longitude: 106.740861,
                district: "District 2",
                ward: "Thao Dien Ward",
                address: "Thao Dien Village",
                drainType: "combined",
                lastMaintained: Date().addingTimeInterval(-60*60*24*22), // 22 days ago
                conditionRating: 4.5,
                reportCount: 0
            ),
            
            // District 10
            Drain(
                id: nil,
                title: "3 Thang 2 Street - District 10",
                latitude: 10.773256,
                longitude: 106.671493,
                district: "District 10",
                ward: "Ward 12",
                address: "3 Thang 2 St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*48), // 48 days ago
                conditionRating: 3.0,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Su Van Hanh Street - District 10",
                latitude: 10.782435,
                longitude: 106.669234,
                district: "District 10",
                ward: "Ward 13",
                address: "Su Van Hanh St",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*33), // 33 days ago
                conditionRating: 3.5,
                reportCount: 0
            ),
            
            // Go Vap District
            Drain(
                id: nil,
                title: "Quang Trung Street - Go Vap",
                latitude: 10.837452,
                longitude: 106.678234,
                district: "Go Vap District",
                ward: "Ward 10",
                address: "Quang Trung St",
                drainType: "street",
                lastMaintained: Date().addingTimeInterval(-60*60*24*52), // 52 days ago
                conditionRating: 2.5,
                reportCount: 0
            ),
            
            Drain(
                id: nil,
                title: "Pham Van Dong Boulevard - Go Vap",
                latitude: 10.846723,
                longitude: 106.675431,
                district: "Go Vap District",
                ward: "Ward 13",
                address: "Pham Van Dong Blvd",
                drainType: "storm",
                lastMaintained: Date().addingTimeInterval(-60*60*24*38), // 38 days ago
                conditionRating: 3.0,
                reportCount: 0
            )
        ]
    }
}
