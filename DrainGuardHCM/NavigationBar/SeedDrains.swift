//
//  SeedDrains.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import FirebaseFirestore

/// Call this function once to seed the drains collection
/// Then delete this file
///
/// HOW TO USE:
/// 1. Add this to any view's .onAppear { seedDrainsToFirebase() }
/// 2. Run the app
/// 3. Check console for progress
/// 4. Verify in Firebase Console -> Firestore -> drains collection
/// 5. Delete this file after seeding
func seedDrainsToFirebase() {
    print("\n🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱")
    print("🌱 DRAIN SEEDER CALLED!")
    print("🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱\n")
    
    Task {
        do {
            let db = Firestore.firestore()
            
            // Check if drains already exist
            print("🌱 [SEEDER] Checking if drains already exist...")
            let existingSnapshot = try await db.collection("drains").limit(to: 1).getDocuments()
            
            if !existingSnapshot.documents.isEmpty {
                print("⚠️ [SEEDER] Drains collection already has data!")
                print("⚠️ [SEEDER] Found \(existingSnapshot.documents.count) existing documents")
                print("⚠️ [SEEDER] Skipping seeding to avoid duplicates")
                print("⚠️ [SEEDER] If you want to re-seed, delete the collection first in Firebase Console\n")
                return
            }
            
            print("✅ [SEEDER] Collection is empty, starting seeding...\n")
            
            let drains = createSampleDrains()
            print("🌱 [SEEDER] Created \(drains.count) sample drains")
            print("🌱 [SEEDER] Firebase app: \(db.app.name)")
            print("🌱 [SEEDER] Starting upload...\n")
            
            var successCount = 0
            var failCount = 0
            
            for (index, drain) in drains.enumerated() {
                do {
                    let drainDict = drain.toDictionary()
                    let docRef = try await db.collection("drains").addDocument(data: drainDict)
                    successCount += 1
                    print("✅ [\(index + 1)/\(drains.count)] \(drain.title)")
                    print("   ID: \(docRef.documentID)")
                } catch {
                    failCount += 1
                    print("❌ [\(index + 1)/\(drains.count)] Failed: \(drain.title)")
                    print("   Error: \(error.localizedDescription)")
                    
                    if let nsError = error as NSError? {
                        print("   Domain: \(nsError.domain)")
                        print("   Code: \(nsError.code)")
                    }
                }
            }
            
            print("\n🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱")
            print("🌱 SEEDING COMPLETE!")
            print("🌱 Success: \(successCount)")
            print("🌱 Failed: \(failCount)")
            print("🌱")
            print("🌱 Now check Firebase Console:")
            print("🌱 Firestore Database -> drains collection")
            print("🌱 You should see \(successCount) documents")
            print("🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱🌱\n")
            
        } catch {
            print("\n❌❌❌ [SEEDER] FATAL ERROR ❌❌❌")
            print("❌ Error: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                print("❌ Domain: \(nsError.domain)")
                print("❌ Code: \(nsError.code)")
                print("❌ UserInfo: \(nsError.userInfo)")
            }
            
            print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌\n")
        }
    }
}

private func createSampleDrains() -> [Drain] {
    [
        Drain(id: nil, title: "Nguyen Hue Walking Street - North", latitude: 10.774520, longitude: 106.702347, district: "District 1", ward: "Ben Nghe Ward", address: "Nguyen Hue St, near Opera House", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*30), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Nguyen Hue Walking Street - South", latitude: 10.772893, longitude: 106.704238, district: "District 1", ward: "Ben Nghe Ward", address: "Nguyen Hue St, near Bach Dang Wharf", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*20), conditionRating: 4.0, reportCount: 0),
        
        Drain(id: nil, title: "Le Loi Boulevard - Pasteur", latitude: 10.774129, longitude: 106.695915, district: "District 1", ward: "Ben Nghe Ward", address: "Le Loi Blvd & Pasteur St", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*45), conditionRating: 3.0, reportCount: 0),
        
        Drain(id: nil, title: "Ben Thanh Market", latitude: 10.772515, longitude: 106.698128, district: "District 1", ward: "Ben Thanh Ward", address: "Le Loi St, Ben Thanh Market", drainType: "combined", lastMaintained: Date().addingTimeInterval(-60*60*24*15), conditionRating: 4.5, reportCount: 0),
        
        Drain(id: nil, title: "Nguyen Trai Street", latitude: 10.768562, longitude: 106.687841, district: "District 1", ward: "Nguyen Cu Trinh Ward", address: "Nguyen Trai St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*60), conditionRating: 2.5, reportCount: 0),
        
        Drain(id: nil, title: "Vo Van Tan Street", latitude: 10.783847, longitude: 106.686752, district: "District 3", ward: "Ward 6", address: "Vo Van Tan St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*50), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Hai Ba Trung Street", latitude: 10.779513, longitude: 106.691247, district: "District 3", ward: "Ward 8", address: "Hai Ba Trung St", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*25), conditionRating: 4.0, reportCount: 0),
        
        Drain(id: nil, title: "Tran Hung Dao Boulevard", latitude: 10.752614, longitude: 106.672836, district: "District 5", ward: "Ward 11", address: "Tran Hung Dao Blvd", drainType: "combined", lastMaintained: Date().addingTimeInterval(-60*60*24*40), conditionRating: 3.0, reportCount: 0),
        
        Drain(id: nil, title: "Nguyen Chi Thanh Street", latitude: 10.755823, longitude: 106.665432, district: "District 5", ward: "Ward 9", address: "Nguyen Chi Thanh St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*35), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Nguyen Van Linh Boulevard", latitude: 10.729847, longitude: 106.719562, district: "District 7", ward: "Tan Phong Ward", address: "Nguyen Van Linh Blvd, Phu My Hung", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*10), conditionRating: 4.5, reportCount: 0),
        
        Drain(id: nil, title: "Crescent Mall Area", latitude: 10.730547, longitude: 106.717834, district: "District 7", ward: "Tan Phu Ward", address: "Ton Dat Tien St, Crescent Mall", drainType: "combined", lastMaintained: Date().addingTimeInterval(-60*60*24*20), conditionRating: 4.0, reportCount: 0),
        
        Drain(id: nil, title: "Xo Viet Nghe Tinh Street", latitude: 10.803452, longitude: 106.701834, district: "Binh Thanh District", ward: "Ward 21", address: "Xo Viet Nghe Tinh St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*55), conditionRating: 2.5, reportCount: 0),
        
        Drain(id: nil, title: "Dien Bien Phu Street", latitude: 10.797623, longitude: 106.692847, district: "Binh Thanh District", ward: "Ward 25", address: "Dien Bien Phu St", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*30), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Phan Dang Luu Street", latitude: 10.799234, longitude: 106.677956, district: "Phu Nhuan District", ward: "Ward 7", address: "Phan Dang Luu St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*42), conditionRating: 3.0, reportCount: 0),
        
        Drain(id: nil, title: "Hoang Van Thu Street", latitude: 10.802451, longitude: 106.673524, district: "Phu Nhuan District", ward: "Ward 9", address: "Hoang Van Thu St", drainType: "combined", lastMaintained: Date().addingTimeInterval(-60*60*24*28), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Hanoi Highway", latitude: 10.797652, longitude: 106.733241, district: "District 2", ward: "Thao Dien Ward", address: "Hanoi Highway", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*18), conditionRating: 4.0, reportCount: 0),
        
        Drain(id: nil, title: "Thao Dien Area", latitude: 10.804523, longitude: 106.740861, district: "District 2", ward: "Thao Dien Ward", address: "Thao Dien Village", drainType: "combined", lastMaintained: Date().addingTimeInterval(-60*60*24*22), conditionRating: 4.5, reportCount: 0),
        
        Drain(id: nil, title: "3 Thang 2 Street", latitude: 10.773256, longitude: 106.671493, district: "District 10", ward: "Ward 12", address: "3 Thang 2 St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*48), conditionRating: 3.0, reportCount: 0),
        
        Drain(id: nil, title: "Su Van Hanh Street", latitude: 10.782435, longitude: 106.669234, district: "District 10", ward: "Ward 13", address: "Su Van Hanh St", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*33), conditionRating: 3.5, reportCount: 0),
        
        Drain(id: nil, title: "Quang Trung Street", latitude: 10.837452, longitude: 106.678234, district: "Go Vap District", ward: "Ward 10", address: "Quang Trung St", drainType: "street", lastMaintained: Date().addingTimeInterval(-60*60*24*52), conditionRating: 2.5, reportCount: 0),
        
        Drain(id: nil, title: "Pham Van Dong Boulevard", latitude: 10.846723, longitude: 106.675431, district: "Go Vap District", ward: "Ward 13", address: "Pham Van Dong Blvd", drainType: "storm", lastMaintained: Date().addingTimeInterval(-60*60*24*38), conditionRating: 3.0, reportCount: 0)
    ]
}
