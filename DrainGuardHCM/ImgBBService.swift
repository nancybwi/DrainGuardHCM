//
//  ImgBBService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import Foundation
import UIKit

/// FREE unlimited image hosting using ImgBB
/// Sign up at: https://imgbb.com/
/// Free tier: UNLIMITED storage & bandwidth!
class ImgBBService {
    
    // TODO: Get your API key from https://api.imgbb.com/
    private let apiKey = "YOUR_IMGBB_API_KEY"
    
    func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
        print("\n📸 [IMGBB] Starting upload...")
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImgBBError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        print("📸 [IMGBB] Image compressed: \(imageData.count / 1024)KB")
        
        // Convert to base64
        let base64Image = imageData.base64EncodedString()
        
        // Create URL with parameters
        var components = URLComponents(string: "https://api.imgbb.com/1/upload")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "image", value: base64Image),
            URLQueryItem(name: "name", value: reportId)
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "ImgBBError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        print("📸 [IMGBB] Uploading to ImgBB...")
        
        // Upload
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ [IMGBB] Upload failed")
            throw NSError(domain: "ImgBBError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        // Parse response
        struct ImgBBResponse: Codable {
            struct Data: Codable {
                let url: String
            }
            let data: Data
            let success: Bool
        }
        
        let result = try JSONDecoder().decode(ImgBBResponse.self, from: data)
        
        guard result.success else {
            throw NSError(domain: "ImgBBError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload not successful"])
        }
        
        print("✅ [IMGBB] Upload successful!")
        print("✅ [IMGBB] URL: \(result.data.url)")
        
        return result.data.url
    }
}

// MARK: - How to Setup ImgBB (FREE & UNLIMITED)

/*
 
 ## Step 1: Get API Key (Takes 30 seconds!)
 
 1. Go to: https://imgbb.com/
 2. Click "Sign up" (or use GitHub/Google)
 3. Go to: https://api.imgbb.com/
 4. Click "Get API Key"
 5. Copy your API key
 
 ## Step 2: Update Code
 
 Replace in this file:
 ```swift
 private let apiKey = "YOUR_IMGBB_API_KEY"
 ```
 
 ## Step 3: Use in ReportService
 
 ```swift
 // In ReportService.swift
 func uploadImage(_ image: UIImage, reportId: String) async throws -> String {
     let imgbb = ImgBBService()
     return try await imgbb.uploadImage(image, reportId: reportId)
 }
 ```
 
 ## Why ImgBB?
 
 ✅ FREE forever
 ✅ UNLIMITED storage
 ✅ UNLIMITED bandwidth
 ✅ No credit card required
 ✅ Simple API
 ✅ Fast CDN
 ✅ Automatic image optimization
 
 Perfect for your app!
 
 */
