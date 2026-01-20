//
//  Report.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//
import Foundation
import FirebaseFirestore
import CoreLocation

/// Main report model that citizens submit and operators manage
struct Report: Identifiable {
    // MARK: - Identity
    @DocumentID var id: String?
    let userId: String
    
    // MARK: - Drain Reference
    /// Reference to the drain being reported
    let drainId: String
    let drainTitle: String // Denormalized for quick display
    let drainLatitude: Double
    let drainLongitude: Double
    
    // MARK: - Report Content
    /// URL to the uploaded image in Firebase Storage
    var imageURL: String
    
    /// User's description of the problem
    let description: String
    
    /// User-reported severity assessment
    let userSeverity: String // "Low", "Medium", "High"
    
    /// How the clog is affecting traffic
    let trafficImpact: String // "Normal", "Slowing", "Blocked"
    
    /// When the report was submitted
    let timestamp: Date
    
    /// User's actual GPS location when reporting (may differ slightly from drain)
    let reporterLatitude: Double
    let reporterLongitude: Double
    let locationAccuracy: Double? // GPS accuracy in meters
    
    // MARK: - AI Validation Results
    /// Whether AI confirmed this is a valid drain clog image
    var isValidated: Bool? // nil = pending, true = valid, false = rejected
    
    /// AI-assessed severity (1-5 scale)
    var aiSeverity: Int? // 1 = minor, 5 = severe
    
    /// AI confidence level (0.0 - 1.0)
    var aiConfidence: Double?
    
    /// When AI processing completed
    var aiProcessedAt: Date?
    
    // MARK: - Risk Scoring
    /// Calculated flood risk score (1.0 - 5.0)
    var riskScore: Double?
    
    /// Factors that contributed to risk score
    var riskFactors: RiskFactors?
    
    // MARK: - Image Processing
    /// Watermarked image URL
    var watermarkedImageURL: String?
    
    /// Perceptual hash for duplicate detection
    var imageHash: String?
    
    // MARK: - Location Intelligence
    /// Near school or university
    var nearSchool: Bool?
    
    /// Near hospital
    var nearHospital: Bool?
    
    /// Distance to nearest school (meters)
    var distanceToSchool: Double?
    
    /// Distance to nearest hospital (meters)
    var distanceToHospital: Double?
    
    /// Submitted during rush hour (5-7 PM in HCMC)
    var submittedDuringRushHour: Bool?
    
    /// List of nearby POIs
    var nearbyPOIs: [String]?
    
    // MARK: - Validation Details
    /// Reason for rejection (if rejected)
    var validationRejectionReason: String?
    
    /// AI detected issue description
    var detectedIssue: String?
    
    /// AI validation reasons
    var validationReasons: [String]?
    
    // MARK: - Status & Workflow
    /// Current user-facing status (saved to Firebase)
    /// This is what users see: "Pending", "In Progress", or "Done"
    var status: ReportStatus
    
    /// Internal workflow state for detailed tracking (optional)
    /// Used for logging: "Sent", "Validating", "Validated", "Rejected", "Assigned", etc.
    /// Not required - status field is the source of truth
    var workflowState: String?
    
    /// ID of the operator assigned to this report
    var assignedTo: String?
    
    /// When the status was last updated
    var statusUpdatedAt: Date?
    
    /// Notes from operators
    var operatorNotes: String?
    
    /// URL to before/after photo from operator
    var afterImageURL: String?
    
    /// When the maintenance was completed
    var completedAt: Date?
}
// MARK: - Supporting Structures

/// Risk calculation breakdown
struct RiskFactors: Codable {
    /// Distance to nearest flood hotspot (meters)
    let distanceToFloodHotspot: Double?
    
    /// Distance to nearest sensitive area like school/hospital (meters)
    let distanceToSensitiveArea: Double?
    
    /// Historical flood frequency at this location
    let historicalFloodCount: Int?
    
    /// Current/forecasted rainfall intensity
    let rainfallIntensity: String? // "None", "Light", "Moderate", "Heavy"
    
    /// Elevation level (lower = higher risk)
    let elevation: Double?
}

// MARK: - Helpers

extension Report {
    /// Computed property for drain location as CLLocationCoordinate2D
    var drainLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: drainLatitude, longitude: drainLongitude)
    }
    
    /// Computed property for reporter's location
    var reporterLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: reporterLatitude, longitude: reporterLongitude)
    }
    
    /// Check if this is a high-priority report
    var isHighPriority: Bool {
        guard let risk = riskScore else { return false }
        return risk >= 4.0
    }
    
    /// User-friendly status display
    var statusDisplay: String {
        status.displayName
    }
    
    /// Color coding for status
    var statusColor: String {
        status.color
    }
}

// MARK: - Firestore Conversion

extension Report {
    /// Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "drainId": drainId,
            "drainTitle": drainTitle,
            "drainLatitude": drainLatitude,
            "drainLongitude": drainLongitude,
            "imageURL": imageURL,
            "description": description,
            "userSeverity": userSeverity,
            "trafficImpact": trafficImpact,
            "timestamp": Timestamp(date: timestamp),
            "reporterLatitude": reporterLatitude,
            "reporterLongitude": reporterLongitude,
            "status": status.rawValue
        ]
        
        // Optional fields
        if let accuracy = locationAccuracy {
            dict["locationAccuracy"] = accuracy
        }
        if let validated = isValidated {
            dict["isValidated"] = validated
        }
        if let severity = aiSeverity {
            dict["aiSeverity"] = severity
        }
        if let confidence = aiConfidence {
            dict["aiConfidence"] = confidence
        }
        if let processedAt = aiProcessedAt {
            dict["aiProcessedAt"] = Timestamp(date: processedAt)
        }
        if let risk = riskScore {
            dict["riskScore"] = risk
        }
        
        // Image processing fields
        if let watermarkedURL = watermarkedImageURL {
            dict["watermarkedImageURL"] = watermarkedURL
        }
        if let hash = imageHash {
            dict["imageHash"] = hash
        }
        
        // Location intelligence fields
        if let nearSchoolVal = nearSchool {
            dict["nearSchool"] = nearSchoolVal
        }
        if let nearHospitalVal = nearHospital {
            dict["nearHospital"] = nearHospitalVal
        }
        if let schoolDist = distanceToSchool {
            dict["distanceToSchool"] = schoolDist
        }
        if let hospitalDist = distanceToHospital {
            dict["distanceToHospital"] = hospitalDist
        }
        if let rushHour = submittedDuringRushHour {
            dict["submittedDuringRushHour"] = rushHour
        }
        if let pois = nearbyPOIs {
            dict["nearbyPOIs"] = pois
        }
        
        // Validation details
        if let rejectionReason = validationRejectionReason {
            dict["validationRejectionReason"] = rejectionReason
        }
        if let issue = detectedIssue {
            dict["detectedIssue"] = issue
        }
        if let reasons = validationReasons {
            dict["validationReasons"] = reasons
        }
        
        // Status & Workflow
        if let workflow = workflowState {
            dict["workflowState"] = workflow
        }
        if let assignee = assignedTo {
            dict["assignedTo"] = assignee
        }
        if let updated = statusUpdatedAt {
            dict["statusUpdatedAt"] = Timestamp(date: updated)
        }
        if let notes = operatorNotes {
            dict["operatorNotes"] = notes
        }
        if let afterURL = afterImageURL {
            dict["afterImageURL"] = afterURL
        }
        if let completed = completedAt {
            dict["completedAt"] = Timestamp(date: completed)
        }
        
        return dict
    }
}

// MARK: - Codable Conformance
extension Report: Codable {
    enum CodingKeys: String, CodingKey {
        case userId, drainId, drainTitle, drainLatitude, drainLongitude
        case imageURL, description, userSeverity, trafficImpact, timestamp
        case reporterLatitude, reporterLongitude, locationAccuracy
        case isValidated, aiSeverity, aiConfidence, aiProcessedAt
        case riskScore, riskFactors
        case watermarkedImageURL, imageHash
        case nearSchool, nearHospital, distanceToSchool, distanceToHospital
        case submittedDuringRushHour, nearbyPOIs
        case validationRejectionReason, detectedIssue, validationReasons
        case status, workflowState, assignedTo, statusUpdatedAt, operatorNotes
        case afterImageURL, completedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Identity
        userId = try container.decode(String.self, forKey: .userId)
        
        // Drain Reference
        drainId = try container.decode(String.self, forKey: .drainId)
        drainTitle = try container.decode(String.self, forKey: .drainTitle)
        drainLatitude = try container.decode(Double.self, forKey: .drainLatitude)
        drainLongitude = try container.decode(Double.self, forKey: .drainLongitude)
        
        // Report Content
        imageURL = try container.decode(String.self, forKey: .imageURL)
        description = try container.decode(String.self, forKey: .description)
        userSeverity = try container.decode(String.self, forKey: .userSeverity)
        trafficImpact = try container.decode(String.self, forKey: .trafficImpact)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        reporterLatitude = try container.decode(Double.self, forKey: .reporterLatitude)
        reporterLongitude = try container.decode(Double.self, forKey: .reporterLongitude)
        locationAccuracy = try container.decodeIfPresent(Double.self, forKey: .locationAccuracy)
        
        // AI Validation Results
        isValidated = try container.decodeIfPresent(Bool.self, forKey: .isValidated)
        aiSeverity = try container.decodeIfPresent(Int.self, forKey: .aiSeverity)
        aiConfidence = try container.decodeIfPresent(Double.self, forKey: .aiConfidence)
        aiProcessedAt = try container.decodeIfPresent(Date.self, forKey: .aiProcessedAt)
        
        // Risk Scoring
        riskScore = try container.decodeIfPresent(Double.self, forKey: .riskScore)
        riskFactors = try container.decodeIfPresent(RiskFactors.self, forKey: .riskFactors)
        
        // Image Processing
        watermarkedImageURL = try container.decodeIfPresent(String.self, forKey: .watermarkedImageURL)
        imageHash = try container.decodeIfPresent(String.self, forKey: .imageHash)
        
        // Location Intelligence
        nearSchool = try container.decodeIfPresent(Bool.self, forKey: .nearSchool)
        nearHospital = try container.decodeIfPresent(Bool.self, forKey: .nearHospital)
        distanceToSchool = try container.decodeIfPresent(Double.self, forKey: .distanceToSchool)
        distanceToHospital = try container.decodeIfPresent(Double.self, forKey: .distanceToHospital)
        submittedDuringRushHour = try container.decodeIfPresent(Bool.self, forKey: .submittedDuringRushHour)
        nearbyPOIs = try container.decodeIfPresent([String].self, forKey: .nearbyPOIs)
        
        // Validation Details
        validationRejectionReason = try container.decodeIfPresent(String.self, forKey: .validationRejectionReason)
        detectedIssue = try container.decodeIfPresent(String.self, forKey: .detectedIssue)
        validationReasons = try container.decodeIfPresent([String].self, forKey: .validationReasons)
        
        // Status & Workflow
        status = try container.decode(ReportStatus.self, forKey: .status)
        workflowState = try container.decodeIfPresent(String.self, forKey: .workflowState)
        assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo)
        statusUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .statusUpdatedAt)
        operatorNotes = try container.decodeIfPresent(String.self, forKey: .operatorNotes)
        afterImageURL = try container.decodeIfPresent(String.self, forKey: .afterImageURL)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Identity
        try container.encode(userId, forKey: .userId)
        
        // Drain Reference
        try container.encode(drainId, forKey: .drainId)
        try container.encode(drainTitle, forKey: .drainTitle)
        try container.encode(drainLatitude, forKey: .drainLatitude)
        try container.encode(drainLongitude, forKey: .drainLongitude)
        
        // Report Content
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(description, forKey: .description)
        try container.encode(userSeverity, forKey: .userSeverity)
        try container.encode(trafficImpact, forKey: .trafficImpact)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(reporterLatitude, forKey: .reporterLatitude)
        try container.encode(reporterLongitude, forKey: .reporterLongitude)
        try container.encodeIfPresent(locationAccuracy, forKey: .locationAccuracy)
        
        // AI Validation Results
        try container.encodeIfPresent(isValidated, forKey: .isValidated)
        try container.encodeIfPresent(aiSeverity, forKey: .aiSeverity)
        try container.encodeIfPresent(aiConfidence, forKey: .aiConfidence)
        try container.encodeIfPresent(aiProcessedAt, forKey: .aiProcessedAt)
        
        // Risk Scoring
        try container.encodeIfPresent(riskScore, forKey: .riskScore)
        try container.encodeIfPresent(riskFactors, forKey: .riskFactors)
        
        // Image Processing
        try container.encodeIfPresent(watermarkedImageURL, forKey: .watermarkedImageURL)
        try container.encodeIfPresent(imageHash, forKey: .imageHash)
        
        // Location Intelligence
        try container.encodeIfPresent(nearSchool, forKey: .nearSchool)
        try container.encodeIfPresent(nearHospital, forKey: .nearHospital)
        try container.encodeIfPresent(distanceToSchool, forKey: .distanceToSchool)
        try container.encodeIfPresent(distanceToHospital, forKey: .distanceToHospital)
        try container.encodeIfPresent(submittedDuringRushHour, forKey: .submittedDuringRushHour)
        try container.encodeIfPresent(nearbyPOIs, forKey: .nearbyPOIs)
        
        // Validation Details
        try container.encodeIfPresent(validationRejectionReason, forKey: .validationRejectionReason)
        try container.encodeIfPresent(detectedIssue, forKey: .detectedIssue)
        try container.encodeIfPresent(validationReasons, forKey: .validationReasons)
        
        // Status & Workflow
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(workflowState, forKey: .workflowState)
        try container.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try container.encodeIfPresent(statusUpdatedAt, forKey: .statusUpdatedAt)
        try container.encodeIfPresent(operatorNotes, forKey: .operatorNotes)
        try container.encodeIfPresent(afterImageURL, forKey: .afterImageURL)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
}

