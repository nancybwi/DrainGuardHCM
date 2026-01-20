//
//  ReportListService.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service to fetch and listen to reports from Firestore with role-based access
@MainActor
class ReportListService: ObservableObject {
    @Published var reports: [Report] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listener: ListenerRegistration?
    private var currentUserId: String?
    private var isAdmin: Bool = false
    
    /// Start listening to reports based on user role
    /// - Parameters:
    ///   - userId: The current user's ID
    ///   - userRole: The user's role ("admin" or "user")
    func startListening(userId: String, userRole: String) {
        print("📊 [ReportListService] Starting listener for user: \(userId), role: \(userRole)")
        
        isLoading = true
        error = nil
        currentUserId = userId
        isAdmin = (userRole == "admin")
        
        // Build query based on role
        var query: Query = Firestore.firestore().collection("reports")
        
        if isAdmin {
            // Admin sees all reports
            print("📊 [ReportListService] Admin mode - fetching ALL reports")
            query = query.order(by: "timestamp", descending: true)
        } else {
            // Regular user sees only their own reports
            print("📊 [ReportListService] User mode - fetching reports for userId: \(userId)")
            query = query
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
        }
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [ReportListService] Error fetching reports: \(error.localizedDescription)")
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ [ReportListService] No documents found")
                self.isLoading = false
                return
            }
            
            print("📊 [ReportListService] Received \(documents.count) reports")
            
            self.reports = documents.compactMap { doc -> Report? in
                self.parseReport(from: doc)
            }
            
            print("📊 [ReportListService] Successfully parsed \(self.reports.count) reports")
            self.isLoading = false
        }
    }
    
    /// Parse a Report from Firestore document
    private func parseReport(from doc: QueryDocumentSnapshot) -> Report? {
        let data = doc.data()
        
        // Parse all fields from Firestore
        guard let userId = data["userId"] as? String,
              let drainId = data["drainId"] as? String,
              let drainTitle = data["drainTitle"] as? String,
              let drainLat = data["drainLatitude"] as? Double,
              let drainLon = data["drainLongitude"] as? Double,
              let imageURL = data["imageURL"] as? String,
              let description = data["description"] as? String,
              let userSeverity = data["userSeverity"] as? String,
              let trafficImpact = data["trafficImpact"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let reporterLat = data["reporterLatitude"] as? Double,
              let reporterLon = data["reporterLongitude"] as? Double,
              let statusRaw = data["status"] as? String,
              let status = ReportStatus(rawValue: statusRaw)
        else {
            print("⚠️ [ReportListService] Failed to parse required fields for document: \(doc.documentID)")
            return nil
        }
        
        var report = Report(
            id: doc.documentID,
            userId: userId,
            drainId: drainId,
            drainTitle: drainTitle,
            drainLatitude: drainLat,
            drainLongitude: drainLon,
            imageURL: imageURL,
            description: description,
            userSeverity: userSeverity,
            trafficImpact: trafficImpact,
            timestamp: timestamp,
            reporterLatitude: reporterLat,
            reporterLongitude: reporterLon,
            locationAccuracy: data["locationAccuracy"] as? Double,
            status: status
        )
        
        // Optional AI validation fields
        report.isValidated = data["isValidated"] as? Bool
        report.aiSeverity = data["aiSeverity"] as? Int
        report.aiConfidence = data["aiConfidence"] as? Double
        report.aiProcessedAt = (data["aiProcessedAt"] as? Timestamp)?.dateValue()
        
        // Risk scoring
        report.riskScore = data["riskScore"] as? Double
        
        // Image processing
        report.watermarkedImageURL = data["watermarkedImageURL"] as? String
        report.imageHash = data["imageHash"] as? String
        
        // Location intelligence
        report.nearSchool = data["nearSchool"] as? Bool
        report.nearHospital = data["nearHospital"] as? Bool
        report.distanceToSchool = data["distanceToSchool"] as? Double
        report.distanceToHospital = data["distanceToHospital"] as? Double
        report.submittedDuringRushHour = data["submittedDuringRushHour"] as? Bool
        report.nearbyPOIs = data["nearbyPOIs"] as? [String]
        
        // Validation details
        report.validationRejectionReason = data["validationRejectionReason"] as? String
        report.detectedIssue = data["detectedIssue"] as? String
        report.validationReasons = data["validationReasons"] as? [String]
        
        // Workflow
        report.workflowState = data["workflowState"] as? String
        report.assignedTo = data["assignedTo"] as? String
        report.statusUpdatedAt = (data["statusUpdatedAt"] as? Timestamp)?.dateValue()
        report.operatorNotes = data["operatorNotes"] as? String
        report.afterImageURL = data["afterImageURL"] as? String
        report.completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
        
        return report
    }
    
    /// Stop listening to Firestore updates
    func stopListening() {
        print("📊 [ReportListService] Stopping listener")
        listener?.remove()
        listener = nil
    }
}
