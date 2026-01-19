//
//  ReportServiceCloudinary.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReportServiceCloudinary: ObservableObject {
    
    private let db = Firestore.firestore()
    private let cloudinary = CloudinaryService()
    
    @Published var uploadProgress: Double = 0
    @Published var uploadError: String?
    
    // MARK: - Upload Image to Cloudinary
    
    func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
        return try await cloudinary.uploadImage(image, reportId: reportId)
    }
    
    // MARK: - Save Report to Firestore
    
    func saveReport(_ report: Report) async throws -> String {
        print("\n💾 [FIRESTORE] Saving report to Firestore...")
        print("💾 [FIRESTORE] User ID: \(report.userId)")
        
        do {
            let reportDict = report.toDictionary()
            let docRef = try await db.collection("reports").addDocument(data: reportDict)
            
            print("✅ [FIRESTORE] Report saved with ID: \(docRef.documentID)\n")
            return docRef.documentID
            
        } catch {
            print("❌ [FIRESTORE] Failed: \(error.localizedDescription)\n")
            throw ReportError.firestoreSaveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Complete Submission
    
    func submitReport(image: UIImage, report: Report) async throws -> String {
        print("\n🚀 [SUBMIT] Starting report submission")
        
        let tempReportId = UUID().uuidString
        
        guard Auth.auth().currentUser != nil else {
            throw ReportError.uploadFailed("User not authenticated")
        }
        
        await MainActor.run {
            self.uploadProgress = 0
            self.uploadError = nil
        }
        
        do {
            // Step 1: Upload image to Cloudinary
            print("📤 Step 1/2: Uploading to Cloudinary...")
            let imageURL = try await uploadImage(image, reportId: tempReportId)
            print("✅ Image URL: \(imageURL)")
            
            // Step 2: Save report to Firestore
            print("💾 Step 2/2: Saving to Firestore...")
            var reportWithImage = report
            reportWithImage.imageURL = imageURL
            
            let reportId = try await saveReport(reportWithImage)
            
            print("✅ Complete submission successful! ID: \(reportId)\n")
            return reportId
            
        } catch {
            await MainActor.run {
                self.uploadError = error.localizedDescription
            }
            print("❌ Submission failed: \(error.localizedDescription)\n")
            throw error
        }
    }
    
    // MARK: - Fetch Reports
    
    func fetchUserReports(userId: String) async throws -> [Report] {
        do {
            let snapshot = try await db.collection("reports")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { try? $0.data(as: Report.self) }
        } catch {
            throw ReportError.fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Update Report Status
    
    func updateReportStatus(reportId: String, status: String, notes: String? = nil) async throws {
        var updateData: [String: Any] = [
            "status": status,
            "statusUpdatedAt": Timestamp(date: Date())
        ]
        
        if let notes = notes {
            updateData["operatorNotes"] = notes
        }
        
        try await db.collection("reports").document(reportId).updateData(updateData)
    }
}

