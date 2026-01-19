//
//  CloudinaryService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import UIKit

/// Free alternative to Firebase Storage using Cloudinary
/// Sign up at: https://cloudinary.com/users/register/free
/// Free tier: 25GB storage, 25GB bandwidth/month
class CloudinaryService {
    
    // TODO: Replace with your Cloudinary credentials from dashboard
    private let cloudName = "dnn4eavlt"  // Get from cloudinary.com dashboard
    private let uploadPreset = "Hackaventure"  // Create unsigned preset in settings
    
    func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
        print("\n☁️ [CLOUDINARY] Starting upload...")
        
        // Compress image intelligently to stay under 10MB limit
        let maxSizeBytes = 10 * 1024 * 1024 // 10MB
        let targetSizeBytes = 8 * 1024 * 1024 // Target 8MB to leave headroom
        
        var compressionQuality: CGFloat = 0.85
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Iteratively reduce quality if needed
        var attempts = 0
        while let data = imageData, data.count > targetSizeBytes && compressionQuality > 0.3 {
            compressionQuality -= 0.05
            imageData = image.jpegData(compressionQuality: compressionQuality)
            attempts += 1
            
            if let data = imageData {
                print("☁️ [CLOUDINARY] Compression attempt \(attempts): \(data.count / 1024)KB at \(Int(compressionQuality * 100))%")
            }
        }
        
        guard let finalImageData = imageData else {
            throw NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let sizeKB = finalImageData.count / 1024
        let sizeMB = Double(finalImageData.count) / 1024.0 / 1024.0
        
        print("☁️ [CLOUDINARY] Image compressed: \(sizeKB)KB (\(String(format: "%.2f", sizeMB))MB) at \(Int(compressionQuality * 100))% quality")
        
        // Double check size
        if finalImageData.count > maxSizeBytes {
            throw NSError(domain: "CloudinaryError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Image too large even after compression (\(String(format: "%.2f", sizeMB))MB). Please take a smaller photo."])
        }
        
        // Create upload URL
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        
        // Create multipart form data
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // Add folder (optional)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("drainguard/reports\r\n".data(using: .utf8)!)
        
        // Add public_id (filename)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"public_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(reportId)\r\n".data(using: .utf8)!)
        
        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(finalImageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("☁️ [CLOUDINARY] Uploading to Cloudinary...")
        
        // Upload
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [CLOUDINARY] Invalid response")
            throw NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("☁️ [CLOUDINARY] Response status: \(httpResponse.statusCode)")
        
        // Log response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("☁️ [CLOUDINARY] Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [CLOUDINARY] Upload failed with status: \(httpResponse.statusCode)")
            
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ [CLOUDINARY] Error message: \(message)")
                throw NSError(domain: "CloudinaryError", code: httpResponse.statusCode, 
                            userInfo: [NSLocalizedDescriptionKey: "Cloudinary error: \(message)"])
            }
            
            throw NSError(domain: "CloudinaryError", code: httpResponse.statusCode, 
                        userInfo: [NSLocalizedDescriptionKey: "Upload failed with status \(httpResponse.statusCode)"])
        }
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let secureUrl = json?["secure_url"] as? String else {
            print("❌ [CLOUDINARY] No secure_url in response")
            throw NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No URL in response"])
        }
        
        print("✅ [CLOUDINARY] Upload successful!")
        print("✅ [CLOUDINARY] URL: \(secureUrl)")
        
        return secureUrl
    }
}

// MARK: - How to Setup Cloudinary (FREE)

/*
 
 ## Step 1: Sign Up (Free)
 
 1. Go to: https://cloudinary.com/users/register/free
 2. Sign up with email
 3. Verify email
 4. Free tier includes:
    - 25GB storage
    - 25GB bandwidth/month
    - 25,000 transformations/month
 
 ## Step 2: Get Credentials
 
 1. Login to Cloudinary dashboard
 2. Copy your "Cloud Name" from dashboard
 3. Go to Settings → Upload → Upload presets
 4. Click "Add upload preset"
 5. Set signing mode to "Unsigned"
 6. Copy the preset name
 
 ## Step 3: Update Code
 
 Replace in this file:
 ```swift
 private let cloudName = "YOUR_CLOUD_NAME"  // From dashboard
 private let uploadPreset = "YOUR_UPLOAD_PRESET"  // From upload presets
 ```
 
 ## Step 4: Use in ReportService
 
 Replace the Firebase Storage upload with Cloudinary:
 
 ```swift
 // In ReportService.swift
 func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
     let cloudinary = CloudinaryService()
     return try await cloudinary.uploadImage(image, reportId: reportId)
 }
 ```
 
 That's it! No Firebase Storage costs!
 
 */
