//
//  AIValidationService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import Foundation
import UIKit

class AIValidationService {
    
    // MARK: - Configuration
    
    private let apiKey: String
    private let model: String
    private let minimumConfidence: Double = 0.7
    
    init() {
        // Read from Config.xcconfig
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              let model = Bundle.main.object(forInfoDictionaryKey: "GEMINI_MODEL") as? String else {
            fatalError("⚠️ Gemini API Key or Model not found in Info.plist. Check Config.xcconfig setup.")
        }
        
        // Validate that values are not empty
        guard !apiKey.isEmpty else {
            fatalError("⚠️ GEMINI_API_KEY is empty in Info.plist")
        }
        guard !model.isEmpty else {
            fatalError("⚠️ GEMINI_MODEL is empty in Info.plist")
        }
        
        self.apiKey = apiKey
        self.model = model
        
        print("🤖 [AI] AIValidationService initialized")
        print("🤖 [AI] Model: \(model)")
        print("🤖 [AI] API Key length: \(apiKey.count) chars")
    }
    
    // MARK: - Validate Report
    
    /// Main validation method
    func validateReport(
        image: UIImage,
        description: String,
        userSeverity: String,
        trafficImpact: String,
        latitude: Double,
        longitude: Double,
        drainId: String,
        drainTitle: String,
        timestamp: Date
    ) async throws -> AIValidationResponse {
        
        print("\n🤖 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🤖 [AI] Starting AI validation")
        print("🤖 [AI] Drain: \(drainTitle)")
        print("🤖 [AI] User severity: \(userSeverity)")
        print("🤖 [AI] Traffic impact: \(trafficImpact)")
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ReportError.imageCompressionFailed
        }
        let base64Image = imageData.base64EncodedString()
        print("🤖 [AI] Image encoded to base64 (\(imageData.count / 1024)KB)")
        
        // Create prompt
        let prompt = createValidationPrompt(
            description: description,
            userSeverity: userSeverity,
            trafficImpact: trafficImpact,
            latitude: latitude,
            longitude: longitude,
            drainTitle: drainTitle,
            timestamp: timestamp
        )
        
        print("🤖 [AI] Prompt created (\(prompt.count) chars)")
        
        // Create Gemini request
        let request = GeminiRequest(
            contents: [
                GeminiRequest.GeminiContent(
                    parts: [
                        GeminiRequest.GeminiPart(
                            text: prompt,
                            inlineData: nil
                        ),
                        GeminiRequest.GeminiPart(
                            text: nil,
                            inlineData: GeminiRequest.GeminiInlineData(
                                mimeType: "image/jpeg",
                                data: base64Image
                            )
                        )
                    ]
                )
            ],
            generationConfig: GeminiRequest.GeminiGenerationConfig(
                temperature: 0.4,
                topK: 32,
                topP: 1.0,
                maxOutputTokens: 512, // Increased for gemini-2.5-flash to prevent MAX_TOKENS cutoff
                responseMimeType: "application/json"
            )
        )
        
        // Send to Gemini API
        let response = try await sendToGemini(request: request)
        
        print("🤖 [AI] Validation complete")
        print("🤖 [AI] Result: \(response.isValid ? "✅ VALID" : "❌ INVALID")")
        print("🤖 [AI] Confidence: \(String(format: "%.2f", response.confidence))")
        print("🤖 [AI] AI Severity: \(response.aiSeverity)/5")
        print("🤖 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return response
    }
    
    // MARK: - Create Prompt
    
    private func createValidationPrompt(
        description: String,
        userSeverity: String,
        trafficImpact: String,
        latitude: Double,
        longitude: Double,
        drainTitle: String,
        timestamp: Date
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let dateString = dateFormatter.string(from: timestamp)
        
        return """
        You are an AI assistant for DrainGuard HCM, a system that validates citizen reports of drain blockages in Ho Chi Minh City, Vietnam.
        
        Analyze the provided image and context to determine if this is a legitimate drain blockage report.
        
        **Report Context:**
        - Location: \(drainTitle)
        - Coordinates: \(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude))
        - Timestamp: \(dateString)
        - User Description: "\(description)"
        - User Severity Assessment: \(userSeverity)
        - Traffic Impact: \(trafficImpact)
        
        **Your Task:**
        Analyze the image and determine:
        1. Is this a valid drain blockage/flooding issue? (true/false)
        2. Your confidence level (0.0 to 1.0)
        3. What issue did you detect in the image?
        4. AI severity rating (1-5 scale):
           - 1: Minor issue, no immediate concern
           - 2: Slight blockage, can wait
           - 3: Moderate blockage, needs attention within 24 hours
           - 4: Severe blockage, flooding risk, needs urgent attention
           - 5: Critical emergency, immediate action required
        5. List of reasons supporting your validation
        
        **Validation Criteria:**
        - VALID if: visible drain, water pooling, debris/blockage, flooding, or clear drainage issue
        - INVALID if: no drain visible, unrelated image, poor quality (blurry/dark), spam, or not a drainage issue
        
        **Response Format (JSON only):**
        {
          "is_valid": true or false,
          "confidence": 0.0 to 1.0,
          "detected_issue": "SHORT description (max 50 chars)",
          "ai_severity": 1 to 5,
          "reasons": ["short reason 1", "short reason 2", "short reason 3"]
        }
        
        IMPORTANT: Keep all text fields SHORT and concise. Maximum 50 characters per field.
        Return ONLY the JSON response, no additional text.
        """
    }
    
    // MARK: - Send to Gemini API
    
    private func sendToGemini(request: GeminiRequest) async throws -> AIValidationResponse {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        
        print("🤖 [API] Constructing endpoint...")
        print("🤖 [API] Model value: '\(model)'")
        print("🤖 [API] Model length: \(model.count) chars")
        print("🤖 [API] Full endpoint: \(endpoint)")
        
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw ReportError.uploadFailed("Invalid API endpoint")
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            throw ReportError.uploadFailed("Failed to construct URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        print("🤖 [API] Sending request to Gemini...")
        print("🤖 [API] Endpoint: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReportError.uploadFailed("Invalid response")
        }
        
        print("🤖 [API] Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [API] Error response: \(errorText)")
            
            // Provide user-friendly error messages
            switch httpResponse.statusCode {
            case 404:
                throw ReportError.uploadFailed("AI model not found. Please check your configuration.")
            case 503:
                throw ReportError.uploadFailed("AI service is temporarily busy. Please try again in a moment.")
            case 429:
                throw ReportError.uploadFailed("Too many requests. Please wait a moment and try again.")
            case 401, 403:
                throw ReportError.uploadFailed("API authentication failed. Please check your API key.")
            default:
                throw ReportError.uploadFailed("AI validation failed (Error \(httpResponse.statusCode)). Please try again.")
            }
        }
        
        // Parse Gemini response
        print("🔍 [DEBUG] ========================================")
        print("🔍 [DEBUG] RAW RESPONSE DATA:")
        if let rawResponseString = String(data: data, encoding: .utf8) {
            print("🔍 [DEBUG] \(rawResponseString)")
        } else {
            print("🔍 [DEBUG] Unable to convert data to string")
        }
        print("🔍 [DEBUG] Data size: \(data.count) bytes")
        print("🔍 [DEBUG] ========================================")
        
        let decoder = JSONDecoder()
        let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
        
        if let error = geminiResponse.error {
            print("❌ [DEBUG] Gemini returned error: \(error)")
            throw ReportError.uploadFailed("Gemini error: \(error.message)")
        }
        
        print("🔍 [DEBUG] Gemini response decoded successfully")
        print("🔍 [DEBUG] Candidates count: \(geminiResponse.candidates?.count ?? 0)")
        
        guard let candidate = geminiResponse.candidates?.first else {
            print("❌ [DEBUG] No candidates in response")
            throw ReportError.uploadFailed("No response from Gemini")
        }
        
        print("🔍 [DEBUG] Candidate parts count: \(candidate.content.parts.count)")
        
        guard let text = candidate.content.parts.first?.text else {
            print("❌ [DEBUG] No text in candidate parts")
            throw ReportError.uploadFailed("No response from Gemini")
        }
        
        print("🤖 [API] Gemini response text: \(text)")
        print("🤖 [API] Response length: \(text.count) chars")
        
        // Check if response was cut off
        if let finishReason = candidate.finishReason {
            print("🤖 [API] Finish reason: \(finishReason)")
            if finishReason != "STOP" {
                print("⚠️ [API] Warning: Response may be incomplete (finish reason: \(finishReason))")
                
                // If response was cut off, throw specific error
                if finishReason == "MAX_TOKENS" {
                    throw ReportError.uploadFailed("AI response was cut off. Please try again.")
                } else if finishReason == "SAFETY" {
                    throw ReportError.uploadFailed("AI response blocked by safety filters.")
                }
            }
        }
        
        // Clean the response - remove markdown code blocks if present
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove ```json and ``` if present
        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🤖 [API] Removed markdown code blocks")
        } else if cleanedText.hasPrefix("```") {
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🤖 [API] Removed markdown code blocks")
        }
        
        // Check if JSON is complete
        let openBraces = cleanedText.filter { $0 == "{" }.count
        let closeBraces = cleanedText.filter { $0 == "}" }.count
        
        if openBraces != closeBraces {
            print("⚠️ [API] JSON appears incomplete: \(openBraces) open braces, \(closeBraces) close braces")
            print("⚠️ [API] Raw text: \(text)")
            throw ReportError.uploadFailed("Gemini response was incomplete. The API may have hit a token limit or network issue.")
        }
        
        print("🤖 [API] Cleaned JSON: \(cleanedText)")
        
        // Validate JSON completeness before parsing
        guard cleanedText.hasPrefix("{") && cleanedText.hasSuffix("}") else {
            print("❌ [API] JSON does not have proper opening and closing braces")
            throw ReportError.uploadFailed("Incomplete AI response. Please try again.")
        }
        
        // Parse AI validation response from JSON text
        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw ReportError.uploadFailed("Failed to convert response to data")
        }
        
        let validationResponse: AIValidationResponse
        do {
            validationResponse = try decoder.decode(AIValidationResponse.self, from: jsonData)
        } catch {
            print("❌ [API] JSON Decode Error: \(error)")
            print("❌ [API] Failed to parse: \(cleanedText)")
            print("❌ [API] Error details: \(String(describing: error))")
            
            // Try to extract partial data if possible
            if let partialDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("⚠️ [API] Partial JSON data: \(partialDict)")
            }
            
            throw ReportError.uploadFailed("AI response format error. Please try again.")
        }
        
        // ═══════════════════════════════════════════════════════════
        // 🎯 DETAILED AI RESPONSE LOGGING
        // ═══════════════════════════════════════════════════════════
        print("\n🎯 ═══════════════════════════════════════════════════════")
        print("🎯 AI VALIDATION RESPONSE (Parsed)")
        print("🎯 ═══════════════════════════════════════════════════════")
        print("🎯 Valid: \(validationResponse.isValid ? "✅ YES" : "❌ NO")")
        print("🎯 Confidence: \(String(format: "%.1f%%", validationResponse.confidence * 100))")
        print("🎯 AI Severity: \(validationResponse.aiSeverity)/5")
        print("🎯 Detected Issue: \(validationResponse.detectedIssue)")
        print("🎯 Reasons:")
        for (index, reason) in validationResponse.reasons.enumerated() {
            print("🎯   \(index + 1). \(reason)")
        }
        print("🎯 ═══════════════════════════════════════════════════════\n")
        
        // Check minimum confidence
        if validationResponse.confidence < minimumConfidence {
            print("⚠️ [AI] Confidence \(validationResponse.confidence) below threshold \(minimumConfidence)")
        }
        
        return validationResponse
    }
}
