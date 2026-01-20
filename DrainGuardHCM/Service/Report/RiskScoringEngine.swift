//
//  RiskScoringEngine.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import Foundation

class RiskScoringEngine {
    
    // MARK: - Calculate Risk Score
    
    /// Calculate comprehensive risk score (1.0 - 5.0)
    func calculateRiskScore(
        aiSeverity: Int,
        aiConfidence: Double,
        userSeverity: String,
        trafficImpact: String,
        locationIntelligence: LocationIntelligence,
        gpsAccuracy: Double?
    ) -> Double {
        
        print("⚠️ [RISK] Calculating risk score...")
        print("⚠️ [RISK] AI Severity: \(aiSeverity)")
        print("⚠️ [RISK] AI Confidence: \(String(format: "%.2f", aiConfidence))")
        
        // Base score from AI severity (1-5)
        var riskScore = Double(aiSeverity)
        print("⚠️ [RISK] Base score: \(riskScore)")
        
        // MODIFIER 1: Near school/hospital (+1.0)
        if locationIntelligence.nearSchool || locationIntelligence.nearHospital {
            riskScore += 1.0
            print("⚠️ [RISK] +1.0 (near sensitive area)")
            
            if locationIntelligence.nearSchool {
                print("   - Near school: \(locationIntelligence.distanceToSchool.map { String(format: "%.0fm", $0) } ?? "N/A")")
            }
            if locationIntelligence.nearHospital {
                print("   - Near hospital: \(locationIntelligence.distanceToHospital.map { String(format: "%.0fm", $0) } ?? "N/A")")
            }
        }
        
        // MODIFIER 2: Rush hour (+0.5)
        if locationIntelligence.submittedDuringRushHour {
            riskScore += 0.5
            print("⚠️ [RISK] +0.5 (rush hour)")
        }
        
        // MODIFIER 3: User severity higher than AI (+0.5)
        let userSeverityValue = convertSeverityToValue(userSeverity)
        if userSeverityValue > aiSeverity {
            riskScore += 0.5
            print("⚠️ [RISK] +0.5 (user concern higher than AI)")
        }
        
        // MODIFIER 4: Traffic blocked (+0.3)
        if trafficImpact.lowercased() == "blocked" {
            riskScore += 0.3
            print("⚠️ [RISK] +0.3 (traffic blocked)")
        } else if trafficImpact.lowercased() == "slowing" {
            riskScore += 0.15
            print("⚠️ [RISK] +0.15 (traffic slowing)")
        }
        
        // MODIFIER 5: Poor GPS accuracy (-0.3)
        if let accuracy = gpsAccuracy, accuracy > 50 {
            riskScore -= 0.3
            print("⚠️ [RISK] -0.3 (poor GPS accuracy: \(String(format: "%.1fm", accuracy)))")
        }
        
        // MODIFIER 6: Low AI confidence (-0.5)
        if aiConfidence < 0.8 {
            riskScore -= 0.3
            print("⚠️ [RISK] -0.3 (AI confidence below 0.8)")
        }
        
        // Clamp to 1.0 - 5.0 range
        riskScore = max(1.0, min(5.0, riskScore))
        
        print("⚠️ [RISK] Final risk score: \(String(format: "%.2f", riskScore))")
        print("⚠️ [RISK] Priority: \(getRiskPriority(score: riskScore))")
        
        return riskScore
    }
    
    // MARK: - Helper Methods
    
    private func convertSeverityToValue(_ severity: String) -> Int {
        switch severity.lowercased() {
        case "low": return 2
        case "medium": return 3
        case "high": return 4
        default: return 3
        }
    }
    
    private func getRiskPriority(score: Double) -> String {
        switch score {
        case 4.5...:
            return "🔴 CRITICAL"
        case 3.5..<4.5:
            return "🟠 HIGH"
        case 2.5..<3.5:
            return "🟡 MEDIUM"
        default:
            return "🟢 LOW"
        }
    }
    
    // MARK: - Should Auto-Assign
    
    /// Determine if this report should be auto-assigned to operators
    func shouldAutoAssign(riskScore: Double) -> Bool {
        return riskScore >= 4.0
    }
    
    // MARK: - Generate Risk Summary
    
    func generateRiskSummary(
        riskScore: Double,
        locationIntelligence: LocationIntelligence,
        aiResponse: AIValidationResponse
    ) -> String {
        var summary = "Risk Score: \(String(format: "%.1f", riskScore))/5.0\n"
        summary += "Priority: \(getRiskPriority(score: riskScore))\n\n"
        
        summary += "AI Analysis:\n"
        summary += "- \(aiResponse.detectedIssue)\n"
        summary += "- Confidence: \(String(format: "%.0f%%", aiResponse.confidence * 100))\n"
        summary += "- Severity: \(aiResponse.aiSeverity)/5\n\n"
        
        summary += "Location Factors:\n"
        if locationIntelligence.nearSchool {
            summary += "- ⚠️ Near school/university\n"
        }
        if locationIntelligence.nearHospital {
            summary += "- ⚠️ Near hospital\n"
        }
        if locationIntelligence.submittedDuringRushHour {
            summary += "- ⏰ Submitted during rush hour\n"
        }
        
        if !locationIntelligence.nearbyPOIs.isEmpty {
            summary += "\nNearby POIs:\n"
            for poi in locationIntelligence.nearbyPOIs.prefix(3) {
                summary += "- \(poi)\n"
            }
        }
        
        return summary
    }
}
