//
//  ReportService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReportService: ObservableObject {
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    @Published var uploadProgress: Double = 0
    @Published var uploadError: String?
    
    init() {
        // Debug: Check Firebase initialization
        print("🔧 [INIT] ReportService initialized")
        print("🔧 [INIT] Firebase Storage bucket: \(storage.reference().bucket)")
        print("🔧 [INIT] Firestore app name: \(db.app.name)")
    }
    
    // MARK: - Upload Image to Storage
    
    /// Upload image to Firebase Storage and return download URL
    func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 [UPLOAD] Starting image upload")
        print("📤 [UPLOAD] Report ID: \(reportId)")
        print("📤 [UPLOAD] Image size: \(image.size.width)x\(image.size.height)")
        
        // Compress image to reduce upload size
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ [UPLOAD] FAILED: Could not compress image to JPEG")
            throw ReportError.imageCompressionFailed
        }
        
        let sizeKB = imageData.count / 1024
        print("📤 [UPLOAD] Image compressed: \(sizeKB)KB")
        
        // Create storage reference
        let storageRef = storage.reference()
        print("📤 [UPLOAD] Storage bucket: \(storageRef.bucket)")
        
        let imageRef = storageRef.child("reports/\(reportId)/photo.jpg")
        print("📤 [UPLOAD] Full path: \(imageRef.fullPath)")
        print("📤 [UPLOAD] Storage URL: gs://\(storageRef.bucket)/\(imageRef.fullPath)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        print("📤 [UPLOAD] Metadata: Content-Type = \(metadata.contentType ?? "nil")")
        
        // Upload with progress tracking
        do {
            print("📤 [UPLOAD] Starting upload task...")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            // Upload data
            let uploadMetadata = try await imageRef.putDataAsync(imageData, metadata: metadata) { [weak self] progress in
                if let progress = progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    let completed = progress.completedUnitCount / 1024
                    let total = progress.totalUnitCount / 1024
                    
                    Task { @MainActor in
                        self?.uploadProgress = percentComplete
                        print("📤 [PROGRESS] \(Int(percentComplete * 100))% (\(completed)KB / \(total)KB)")
                    }
                }
            }
            
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[UPLOAD] Upload completed!")
            print("[UPLOAD] Uploaded size: \(uploadMetadata.size ?? 0) bytes")
            print("[UPLOAD] Content type: \(uploadMetadata.contentType ?? "unknown")")
            print("[UPLOAD] Path: \(uploadMetadata.path ?? "unknown")")
            print("[UPLOAD] Now fetching download URL...")
            
            // Small delay to ensure Firebase processes the file
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            // Get download URL with retry logic
            var downloadURL: URL?
            var attempts = 0
            let maxAttempts = 3
            
            print("[URL] Attempting to get download URL (max \(maxAttempts) attempts)...")
            
            while downloadURL == nil && attempts < maxAttempts {
                do {
                    attempts += 1
                    print("[URL] Attempt \(attempts)/\(maxAttempts)...")
                    downloadURL = try await imageRef.downloadURL()
                    print("[URL] SUCCESS on attempt \(attempts)!")
                    print("[URL] Download URL: \(downloadURL?.absoluteString ?? "nil")")
                } catch let urlError {
                    print("[URL] FAILED on attempt \(attempts)")
                    print("[URL] Error: \(urlError.localizedDescription)")
                    print("[URL] Error type: \(type(of: urlError))")
                    
                    // Print more detailed error info
                    if let nsError = urlError as NSError? {
                        print("[URL] Domain: \(nsError.domain)")
                        print("[URL] Code: \(nsError.code)")
                        print("[URL] UserInfo: \(nsError.userInfo)")
                    }
                    
                    if attempts < maxAttempts {
                        print("[URL] Waiting 1 second before retry...")
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    } else {
                        print("[URL] All attempts exhausted. Throwing error.")
                        throw urlError
                    }
                }
            }
            
            guard let urlString = downloadURL?.absoluteString else {
                print("[URL] FATAL: downloadURL is nil even though no error was thrown!")
                throw ReportError.uploadFailed("Could not get download URL")
            }
            
            print("[UPLOAD] COMPLETE SUCCESS!")
            print("[UPLOAD] Final URL: \(urlString)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return urlString
            
        } catch {
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[UPLOAD] FAILED!")
            print("[UPLOAD] Error: \(error.localizedDescription)")
            print("[UPLOAD] Error type: \(type(of: error))")
            
            if let nsError = error as NSError? {
                print("❌ [UPLOAD] Domain: \(nsError.domain)")
                print("❌ [UPLOAD] Code: \(nsError.code)")
                print("❌ [UPLOAD] UserInfo: \(nsError.userInfo)")
            }
            
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw ReportError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Save Report to Firestore
    
    /// Save report to Firestore
    func saveReport(_ report: Report) async throws -> String {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[FIRESTORE] Saving report to Firestore")
        print("[FIRESTORE] User ID: \(report.userId)")
        print("[FIRESTORE] Drain ID: \(report.drainId)")
        print("[FIRESTORE] Image URL: \(report.imageURL)")
        
        do {
            // Convert report to dictionary
            let reportDict = report.toDictionary()
            print("[FIRESTORE] Report dictionary keys: \(reportDict.keys.joined(separator: ", "))")
            print("[FIRESTORE] Dictionary values:")
            for (key, value) in reportDict {
                print("   - \(key): \(value)")
            }
            
            // Add to Firestore
            print("[FIRESTORE] Adding document to 'reports' collection...")
            let docRef = try await db.collection("reports").addDocument(data: reportDict)
            
            print("✅ [FIRESTORE] SUCCESS!")
            print("✅ [FIRESTORE] Document ID: \(docRef.documentID)")
            print("✅ [FIRESTORE] Collection path: \(docRef.path)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return docRef.documentID
            
        } catch {
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("❌ [FIRESTORE] FAILED!")
            print("❌ [FIRESTORE] Error: \(error.localizedDescription)")
            print("❌ [FIRESTORE] Error type: \(type(of: error))")
            
            if let nsError = error as NSError? {
                print("❌ [FIRESTORE] Domain: \(nsError.domain)")
                print("❌ [FIRESTORE] Code: \(nsError.code)")
                print("❌ [FIRESTORE] UserInfo: \(nsError.userInfo)")
            }
            
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw ReportError.firestoreSaveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Complete Submission (Image + Report)
    
    /// Complete submission: Upload image, save report with image URL
    func submitReport(image: UIImage, report: Report) async throws -> String {
        print("\n")
        print("[SUBMIT] STARTING COMPLETE REPORT SUBMISSION")
        
        // Generate report ID first
        let tempReportId = UUID().uuidString
        print("[SUBMIT] Generated temp report ID: \(tempReportId)")
        
        // Check Firebase Auth
        if let currentUser = Auth.auth().currentUser {
            print("[SUBMIT] User authenticated: \(currentUser.uid)")
            print("[SUBMIT] User email: \(currentUser.email ?? "no email")")
        } else {
            print("❌ [SUBMIT] ERROR: No authenticated user!")
            throw ReportError.uploadFailed("User not authenticated")
        }
        
        // Reset progress
        await MainActor.run {
            self.uploadProgress = 0
            self.uploadError = nil
        }
        
        do {
            // Step 1: Upload image
            print("[SUBMIT] ━━━ STEP 1/2: UPLOADING IMAGE ━━━")
            let imageURL = try await uploadImage(image, reportId: tempReportId)
            print("[SUBMIT] ✅ Step 1 complete. Image URL: \(imageURL)")
            
            // Step 2: Create report with image URL
            print("[SUBMIT] ━━━ STEP 2/2: SAVING REPORT ━━━")
            var reportWithImage = report
            reportWithImage.imageURL = imageURL
            
            let reportId = try await saveReport(reportWithImage)
            print("🚀 [SUBMIT] ✅ Step 2 complete. Report ID: \(reportId)")
            
            print("\n")
            print("[SUBMIT] COMPLETE SUBMISSION SUCCESSFUL!")
            print("[SUBMIT] Report ID: \(reportId)")
            print("[SUBMIT] Image URL: \(imageURL)")
            print("\n")
            
            return reportId
            
        } catch {
            print("\n")
            print("[SUBMIT] SUBMISSION FAILED!")
            print("[SUBMIT] Error: \(error.localizedDescription)")
            print("[SUBMIT] Error type: \(type(of: error))")
            
            if let nsError = error as NSError? {
                print("[SUBMIT] Domain: \(nsError.domain)")
                print("[SUBMIT] Code: \(nsError.code)")
                print("[SUBMIT] UserInfo: \(nsError.userInfo)")
            }
            
            print("\n")
            
            await MainActor.run {
                self.uploadError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Fetch Reports (for status view)
    
    /// Fetch user's reports
    func fetchUserReports(userId: String) async throws -> [Report] {
        print("📥 Fetching reports for user: \(userId)")
        
        do {
            let snapshot = try await db.collection("reports")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            let reports = snapshot.documents.compactMap { doc -> Report? in
                try? doc.data(as: Report.self)
            }
            
            print("✅ Fetched \(reports.count) reports")
            return reports
            
        } catch {
            print("❌ Failed to fetch reports: \(error.localizedDescription)")
            throw ReportError.fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Update Report Status (for operators)
    
    /// Update report status (legacy string-based method)
    func updateReportStatus(reportId: String, status: String, notes: String? = nil) async throws {
        print("🔄 Updating report \(reportId) to status: \(status)")
        
        var updateData: [String: Any] = [
            "status": status,
            "statusUpdatedAt": Timestamp(date: Date())
        ]
        
        if let notes = notes {
            updateData["operatorNotes"] = notes
        }
        
        do {
            try await db.collection("reports").document(reportId).updateData(updateData)
            print("✅ Report status updated")
        } catch {
            print("❌ Failed to update status: \(error.localizedDescription)")
            throw ReportError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Update report status with ReportStatus enum (for admin actions)
    func updateReportStatus(
        reportId: String,
        newStatus: ReportStatus,
        assignedTo: String? = nil,
        operatorNotes: String? = nil
    ) async throws {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[STATUS UPDATE] Starting status update")
        print("[STATUS UPDATE] Report ID: \(reportId)")
        print("[STATUS UPDATE] New Status: \(newStatus.rawValue)")
        
        var updateData: [String: Any] = [
            "status": newStatus.rawValue,
            "statusUpdatedAt": Timestamp(date: Date())
        ]
        
        // If moving to In Progress, assign to admin
        if newStatus == .inProgress {
            if let assignedTo = assignedTo {
                updateData["assignedTo"] = assignedTo
                print("🔄 [STATUS UPDATE] Assigning to: \(assignedTo)")
            }
            updateData["workflowState"] = "In Progress"
        }
        
        // If marking as done, record completion time
        if newStatus == .done {
            updateData["completedAt"] = Timestamp(date: Date())
            updateData["workflowState"] = "Done"
            print("🔄 [STATUS UPDATE] Marking as completed")
        }
        
        // Add notes if provided
        if let notes = operatorNotes {
            updateData["operatorNotes"] = notes
            print("🔄 [STATUS UPDATE] Adding operator notes")
        }
        
        print("🔄 [STATUS UPDATE] Update data: \(updateData)")
        
        do {
            try await db.collection("reports").document(reportId).updateData(updateData)
            print("✅ [STATUS UPDATE] Successfully updated to \(newStatus.rawValue)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        } catch {
            print("❌ [STATUS UPDATE] Failed: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw ReportError.updateFailed(error.localizedDescription)
        }
    }
}

// MARK: - Error Types

enum ReportError: LocalizedError {
    case imageCompressionFailed
    case uploadFailed(String)
    case firestoreSaveFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .firestoreSaveFailed(let message):
            return "Failed to save report: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch reports: \(message)"
        case .updateFailed(let message):
            return "Failed to update report: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Helper Extension for Upload with Progress

extension StorageReference {
    func putDataAsync(_ uploadData: Data, metadata: StorageMetadata?, progressHandler: @escaping (Progress?) -> Void) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { continuation in
            let uploadTask = self.putData(uploadData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageError", code: -1))
                }
            }
            
            // Observe progress
            uploadTask.observe(.progress) { snapshot in
                progressHandler(snapshot.progress)
            }
        }
    }
}
