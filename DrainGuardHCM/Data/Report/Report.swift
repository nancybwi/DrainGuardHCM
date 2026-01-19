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
struct Report: Codable, Identifiable {
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
    
    // MARK: - Status & Workflow
    /// Current status in the workflow
    var status: String // "Sent", "Validating", "Validated", "Rejected", "Assigned", "In Progress", "Done"
    
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
        switch status {
        case "Sent": return "Submitted"
        case "Validating": return "AI Checking..."
        case "Validated": return "Confirmed"
        case "Rejected": return "Not Valid"
        case "Assigned": return "Operator Assigned"
        case "In Progress": return "Being Fixed"
        case "Done": return "Completed"
        default: return status
        }
    }
    
    /// Color coding for status
    var statusColor: String {
        switch status {
        case "Sent", "Validating": return "orange"
        case "Validated", "Assigned": return "blue"
        case "In Progress": return "purple"
        case "Done": return "green"
        case "Rejected": return "red"
        default: return "gray"
        }
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
            "status": status
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

