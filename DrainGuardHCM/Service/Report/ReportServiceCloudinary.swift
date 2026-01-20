//
//  ReportServiceCloudinary.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//  Updated: 19/1/26 - Added AI Validation Pipeline
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReportServiceCloudinary: ObservableObject {
    
    private let db = Firestore.firestore()
    private let cloudinary = CloudinaryService()
    private let validationCoordinator = ReportValidationCoordinator()
    
    @Published var uploadProgress: Double = 0
    @Published var uploadError: String?
    @Published var validationProgress: String = ""
    
    // MARK: - Complete Submission with AI Validation
    
    func submitReport(image: UIImage, report: Report) async throws -> String {
        print("\n🚀 [SUBMIT] Starting report submission with AI validation")
        
        guard Auth.auth().currentUser != nil else {
            throw ReportError.uploadFailed("User not authenticated")
        }
        
        await MainActor.run {
            self.uploadProgress = 0
            self.uploadError = nil
            self.validationProgress = "Starting validation..."
        }
        
        // Use validation coordinator to validate and save
        let (success, reportId, rejectionReason) = try await validationCoordinator.validateAndSubmit(
            image: image,
            report: report
        )
        
        if !success {
            // Report was rejected
            throw ReportError.validationFailed(rejectionReason ?? "Report did not pass validation")
        }
        
        guard let reportId = reportId else {
            throw ReportError.uploadFailed("Failed to get report ID")
        }
        
        print("✅ [SUBMIT] Report submitted successfully with ID: \(reportId)")
        return reportId
    }
    
    // MARK: - Legacy Methods (kept for backwards compatibility)
    
    /// Upload image to Cloudinary (legacy - now handled by validation coordinator)
    func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
        return try await cloudinary.uploadImage(image, reportId: reportId)
    }
    
    /// Save report to Firestore (legacy - now handled by validation coordinator)
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
