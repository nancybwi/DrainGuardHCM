//
//  ReportValidationCoordinator.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import Foundation
import UIKit
import FirebaseFirestore

@MainActor
class ReportValidationCoordinator: ObservableObject {
    
    // MARK: - Services
    
    private let imageProcessor = ImageProcessingService()
    private let locationIntelligence = LocationIntelligenceService()
    private let aiValidator = AIValidationService()
    private let riskEngine = RiskScoringEngine()
    private let db = Firestore.firestore()
    
    // MARK: - Published Properties
    
    @Published var validationProgress: String = ""
    @Published var validationStep: Int = 0
    @Published var totalSteps: Int = 7
    
    // MARK: - Configuration
    
    private let minimumConfidence: Double = 0.7
    private let pHashRetentionDays: Int = 30
    
    // MARK: - Main Validation & Submission
    
    /// Complete validation and submission pipeline
    func validateAndSubmit(
        image: UIImage,
        report: Report
    ) async throws -> (success: Bool, reportId: String?, rejectionReason: String?) {
        
        print("\n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        print("🚀 [VALIDATION] STARTING REPORT VALIDATION PIPELINE")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀\n")
        
        do {
            // STEP 1: Resize and add watermark
            validationStep = 1
            validationProgress = "Preparing image..."
            print("━━━ STEP 1/7: PREPARING & WATERMARKING IMAGE ━━━")
            
            // Resize image to max 2048px width (keeps aspect ratio)
            let resizedImage = imageProcessor.resizeImage(image, maxWidth: 2048)
            print("📐 [RESIZE] Image resized from \(Int(image.size.width))x\(Int(image.size.height)) to \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height))")
            
            let watermarkedImage = imageProcessor.addWatermark(
                to: resizedImage,
                timestamp: report.timestamp,
                latitude: report.reporterLatitude,
                longitude: report.reporterLongitude,
                style: .full
            )
            
            // Check size after watermarking
            if let testData = watermarkedImage.jpegData(compressionQuality: 0.7) {
                let sizeKB = testData.count / 1024
                print("📊 [SIZE] Watermarked image size: \(sizeKB)KB")
                if sizeKB > 10000 {
                    print("⚠️ [SIZE] Warning: Image still over 10MB, Cloudinary may reject")
                }
            }
            
            // STEP 2: Generate pHash
            validationStep = 2
            validationProgress = "Checking for duplicates..."
            print("\n━━━ STEP 2/7: GENERATING PHASH ━━━")
            
            let pHash = imageProcessor.generatePHash(for: watermarkedImage)
            
            // STEP 3: Check for duplicates
            validationStep = 3
            print("\n━━━ STEP 3/7: CHECKING DUPLICATES ━━━")
            
            if try await isDuplicate(pHash: pHash) {
                print("❌ [VALIDATION] REJECTED: Duplicate image detected")
                return (false, nil, "This image has already been submitted. Duplicate reports are not allowed.")
            }
            
            // STEP 4: Upload watermarked image to Cloudinary
            validationStep = 4
            validationProgress = "Uploading image..."
            print("\n━━━ STEP 4/7: UPLOADING IMAGE ━━━")
            
            let cloudinary = CloudinaryService()
            let reportId = UUID().uuidString
            let watermarkedImageURL = try await cloudinary.uploadImage(watermarkedImage, reportId: reportId)
            print("✅ Watermarked image uploaded: \(watermarkedImageURL)")
            
            // STEP 5: Location intelligence
            validationStep = 5
            validationProgress = "Analyzing location..."
            print("\n━━━ STEP 5/7: LOCATION INTELLIGENCE ━━━")
            
            let locationIntel = await locationIntelligence.analyzeLocation(
                latitude: report.reporterLatitude,
                longitude: report.reporterLongitude,
                timestamp: report.timestamp
            )
            
            // STEP 6: AI Validation
            validationStep = 6
            validationProgress = "AI validating report..."
            print("\n━━━ STEP 6/7: AI VALIDATION ━━━")
            
            let aiResponse = try await aiValidator.validateReport(
                image: watermarkedImage,
                description: report.description,
                userSeverity: report.userSeverity,
                trafficImpact: report.trafficImpact,
                latitude: report.reporterLatitude,
                longitude: report.reporterLongitude,
                drainId: report.drainId,
                drainTitle: report.drainTitle,
                timestamp: report.timestamp
            )
            
            // Check if AI validates the report
            if !aiResponse.isValid {
                print("❌ [VALIDATION] REJECTED: AI determined report is not valid")
                print("   Reason: \(aiResponse.detectedIssue)")
                return (false, nil, "AI validation failed: \(aiResponse.detectedIssue)")
            }
            
            // Check minimum confidence
            if aiResponse.confidence < minimumConfidence {
                print("❌ [VALIDATION] REJECTED: Confidence too low (\(aiResponse.confidence) < \(minimumConfidence))")
                return (false, nil, "Image quality or content unclear. Please take a clearer photo showing the drain issue.")
            }
            
            // STEP 7: Calculate risk score
            validationStep = 7
            validationProgress = "Calculating risk score..."
            print("\n━━━ STEP 7/7: RISK SCORING ━━━")
            
            let riskScore = riskEngine.calculateRiskScore(
                aiSeverity: aiResponse.aiSeverity,
                aiConfidence: aiResponse.confidence,
                userSeverity: report.userSeverity,
                trafficImpact: report.trafficImpact,
                locationIntelligence: locationIntel,
                gpsAccuracy: report.locationAccuracy
            )
            
            // Create enhanced report with all validation data
            var validatedReport = report
            validatedReport.imageURL = watermarkedImageURL
            validatedReport.watermarkedImageURL = watermarkedImageURL
            validatedReport.imageHash = pHash
            validatedReport.isValidated = true
            validatedReport.aiSeverity = aiResponse.aiSeverity
            validatedReport.aiConfidence = aiResponse.confidence
            validatedReport.aiProcessedAt = Date()
            validatedReport.riskScore = riskScore
            validatedReport.detectedIssue = aiResponse.detectedIssue
            validatedReport.validationReasons = aiResponse.reasons
            validatedReport.nearSchool = locationIntel.nearSchool
            validatedReport.nearHospital = locationIntel.nearHospital
            validatedReport.distanceToSchool = locationIntel.distanceToSchool
            validatedReport.distanceToHospital = locationIntel.distanceToHospital
            validatedReport.submittedDuringRushHour = locationIntel.submittedDuringRushHour
            validatedReport.nearbyPOIs = locationIntel.nearbyPOIs
            validatedReport.status = "Validated"
            
            // Auto-assign if high priority
            if riskEngine.shouldAutoAssign(riskScore: riskScore) {
                validatedReport.status = "Assigned" // Will need operator assignment logic
                print("🔴 [VALIDATION] High priority! Should auto-assign to operator")
            }
            
            // Save to Firebase
            validationProgress = "Saving to database..."
            print("\n━━━ SAVING TO FIREBASE ━━━")
            
            let savedReportId = try await saveValidatedReport(validatedReport)
            
            // Save pHash for duplicate detection
            try await savePHash(pHash: pHash, reportId: savedReportId)
            
            print("\n✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅")
            print("✅ [VALIDATION] VALIDATION SUCCESSFUL!")
            print("✅ Report ID: \(savedReportId)")
            print("✅ Risk Score: \(String(format: "%.1f", riskScore))/5.0")
            print("✅ AI Confidence: \(String(format: "%.0f%%", aiResponse.confidence * 100))")
            print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅\n")
            
            return (true, savedReportId, nil)
            
        } catch {
            print("\n❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌")
            print("❌ [VALIDATION] VALIDATION FAILED")
            print("❌ Error: \(error.localizedDescription)")
            print("❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌\n")
            throw error
        }
    }
    
    // MARK: - Duplicate Detection
    
    private func isDuplicate(pHash: String) async throws -> Bool {
        print("🔍 [DUPLICATE] Checking for duplicate pHash: \(pHash)")
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -pHashRetentionDays, to: Date())!
        
        do {
            let snapshot = try await db.collection("image_hashes")
                .whereField("imageHash", isEqualTo: pHash)
                .whereField("timestamp", isGreaterThan: Timestamp(date: cutoffDate))
                .getDocuments()
            
            if !snapshot.documents.isEmpty {
                print("⚠️ [DUPLICATE] Found \(snapshot.documents.count) matching hash(es)")
                return true
            }
            
            print("✅ [DUPLICATE] No duplicates found")
            return false
            
        } catch {
            print("⚠️ [DUPLICATE] Error checking duplicates: \(error.localizedDescription)")
            // Don't fail validation if duplicate check fails
            return false
        }
    }
    
    // MARK: - Save to Firebase
    
    private func saveValidatedReport(_ report: Report) async throws -> String {
        print("💾 [FIREBASE] Saving validated report...")
        
        let reportDict = report.toDictionary()
        let docRef = try await db.collection("reports").addDocument(data: reportDict)
        
        print("✅ [FIREBASE] Report saved with ID: \(docRef.documentID)")
        return docRef.documentID
    }
    
    private func savePHash(pHash: String, reportId: String) async throws {
        print("💾 [FIREBASE] Saving pHash for duplicate detection...")
        
        let hashData: [String: Any] = [
            "imageHash": pHash,
            "reportId": reportId,
            "timestamp": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("image_hashes").addDocument(data: hashData)
            print("✅ [FIREBASE] pHash saved")
        } catch {
            // Don't fail the entire submission if pHash saving fails
            print("⚠️ [FIREBASE] Failed to save pHash (non-critical): \(error.localizedDescription)")
            print("⚠️ [FIREBASE] Report will still be saved, but duplicate detection may not work")
        }
    }
}
