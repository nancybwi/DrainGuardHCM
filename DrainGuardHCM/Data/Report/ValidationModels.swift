//
//  ValidationModels.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import Foundation
import UIKit

// MARK: - AI Validation Request

struct AIValidationRequest: Codable {
    let imageURL: String?
    let imageBase64: String?
    let latitude: Double
    let longitude: Double
    let timestamp: String
    let description: String
    let userSeverity: String
    let trafficImpact: String
    let drainId: String
    let drainTitle: String
    
    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case imageBase64 = "image_base64"
        case latitude
        case longitude
        case timestamp
        case description
        case userSeverity = "user_severity"
        case trafficImpact = "traffic_impact"
        case drainId = "drain_id"
        case drainTitle = "drain_title"
    }
}

// MARK: - AI Validation Response

struct AIValidationResponse: Codable {
    let isValid: Bool
    let confidence: Double
    let detectedIssue: String
    let aiSeverity: Int
    let reasons: [String]
    
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case confidence
        case detectedIssue = "detected_issue"
        case aiSeverity = "ai_severity"
        case reasons
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isApproved: Bool
    let aiResponse: AIValidationResponse?
    let rejectionReason: String?
    let riskScore: Double?
    let locationIntelligence: LocationIntelligence?
    let imageHash: String
    let watermarkedImageURL: String
    
    var shouldSaveToFirebase: Bool {
        return isApproved
    }
}

// MARK: - Location Intelligence

struct LocationIntelligence: Codable {
    let nearSchool: Bool
    let nearHospital: Bool
    let distanceToSchool: Double? // meters
    let distanceToHospital: Double? // meters
    let submittedDuringRushHour: Bool
    let nearbyPOIs: [String]
    
    enum CodingKeys: String, CodingKey {
        case nearSchool = "near_school"
        case nearHospital = "near_hospital"
        case distanceToSchool = "distance_to_school"
        case distanceToHospital = "distance_to_hospital"
        case submittedDuringRushHour = "submitted_during_rush_hour"
        case nearbyPOIs = "nearby_pois"
    }
}

// MARK: - Gemini API Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    
    struct GeminiContent: Codable {
        let parts: [GeminiPart]
    }
    
    struct GeminiPart: Codable {
        let text: String?
        let inlineData: GeminiInlineData?
        
        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }
    
    struct GeminiInlineData: Codable {
        let mimeType: String
        let data: String // base64
        
        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data
        }
    }
    
    struct GeminiGenerationConfig: Codable {
        let temperature: Double
        let topK: Int
        let topP: Double
        let maxOutputTokens: Int
        let responseMimeType: String
        
        enum CodingKeys: String, CodingKey {
            case temperature
            case topK
            case topP
            case maxOutputTokens
            case responseMimeType = "response_mime_type"
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
    
    struct GeminiCandidate: Codable {
        let content: GeminiContent
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case content
            case finishReason = "finish_reason"
        }
    }
    
    struct GeminiContent: Codable {
        let parts: [GeminiPart]
        let role: String
    }
    
    struct GeminiPart: Codable {
        let text: String
    }
    
    struct GeminiError: Codable {
        let code: Int
        let message: String
        let status: String
    }
}
