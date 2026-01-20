//
//  ImageProcessingService.swift
//  DrainGuardHCM
//
//  Created by Assistant on 1/19/26.
//

import UIKit
import CoreImage
import CryptoKit

class ImageProcessingService {
    
    // MARK: - Watermark Configuration
    
    enum WatermarkStyle {
        case timestampOnly
        case timestampAndGPS
        case full // Timestamp + GPS + "DrainGuard HCM"
    }
    
    // MARK: - Add Watermark
    
    /// Add watermark to image
    func addWatermark(
        to image: UIImage,
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        style: WatermarkStyle = .full
    ) -> UIImage {
        print("🎨 [WATERMARK] Adding watermark to image...")
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let watermarkedImage = renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Prepare watermark text
            let watermarkText = generateWatermarkText(
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                style: style
            )
            
            // Configure text attributes
            let fontSize: CGFloat = image.size.width * 0.025 // 2.5% of image width
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0 // Negative = filled text with stroke
            ]
            
            // Calculate text size
            let textSize = watermarkText.size(withAttributes: attributes)
            
            // Position at bottom-left with padding
            let padding: CGFloat = image.size.width * 0.02
            let textRect = CGRect(
                x: padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )
            
            // Draw semi-transparent background
            let backgroundRect = textRect.insetBy(dx: -padding/2, dy: -padding/4)
            UIColor.black.withAlphaComponent(0.6).setFill()
            UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8).fill()
            
            // Draw text
            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
        
        print("[WATERMARK] Watermark added successfully")
        return watermarkedImage
    }
    
    private func generateWatermarkText(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        style: WatermarkStyle
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let dateString = dateFormatter.string(from: timestamp)
        
        switch style {
        case .timestampOnly:
            return dateString
            
        case .timestampAndGPS:
            return "\(dateString)\n\(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude))"
            
        case .full:
            return "DrainGuard HCM\n\(dateString)\n\(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude))"
        }
    }
    
    // MARK: - Perceptual Hash (pHash)
    
    /// Generate perceptual hash for duplicate detection
    func generatePHash(for image: UIImage) -> String {
        print("🔢 [PHASH] Generating perceptual hash...")
        
        guard let cgImage = image.cgImage else {
            print("❌ [PHASH] Failed to get CGImage")
            return ""
        }
        
        // Resize to 32x32 for consistency
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        guard let resizedCGImage = resizedImage.cgImage else {
            print("❌ [PHASH] Failed to resize image")
            return ""
        }
        
        // Convert to grayscale
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        
        var pixelData = [UInt8](repeating: 0, count: width * height)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        
        context?.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Calculate average pixel value
        let sum = pixelData.reduce(0, { $0 + Int($1) })
        let average = sum / pixelData.count
        
        // Generate hash: 1 if above average, 0 if below
        var hash: UInt64 = 0
        for (index, pixel) in pixelData.enumerated() {
            if Int(pixel) > average {
                hash |= (1 << (index % 64))
            }
        }
        
        let hashString = String(hash, radix: 16)
        print("[PHASH] Hash generated: \(hashString)")
        return hashString
    }
    
    /// Calculate Hamming distance between two pHashes (for similarity detection)
    func hammingDistance(hash1: String, hash2: String) -> Int {
        guard let num1 = UInt64(hash1, radix: 16),
              let num2 = UInt64(hash2, radix: 16) else {
            return Int.max
        }
        
        let xor = num1 ^ num2
        return xor.nonzeroBitCount
    }
    
    /// Check if two images are similar (returns true if Hamming distance < threshold)
    func areSimilar(hash1: String, hash2: String, threshold: Int = 10) -> Bool {
        let distance = hammingDistance(hash1: hash1, hash2: hash2)
        return distance < threshold
    }
    
    // MARK: - Image Resizing
    
    /// Resize image to a maximum width while maintaining aspect ratio
    func resizeImage(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        let oldWidth = image.size.width
        let oldHeight = image.size.height
        
        // If already smaller, return original
        if oldWidth <= maxWidth {
            print("📐 [RESIZE] Image already small enough (\(Int(oldWidth))px wide)")
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let scaleFactor = maxWidth / oldWidth
        let newWidth = maxWidth
        let newHeight = oldHeight * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        print("📐 [RESIZE] Resizing from \(Int(oldWidth))x\(Int(oldHeight)) to \(Int(newWidth))x\(Int(newHeight))")
        
        // Render at new size
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    // MARK: - Image Compression
    
    /// Compress image for upload
    func compressImage(_ image: UIImage, maxSizeKB: Int = 800) -> Data? {
        print("🗜️ [COMPRESS] Compressing image...")
        
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Iteratively reduce quality until under size limit
        while let data = imageData, data.count / 1024 > maxSizeKB && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
            print("🗜️ [COMPRESS] Trying compression: \(Int(compression * 100))%")
        }
        
        if let finalData = imageData {
            let sizeKB = finalData.count / 1024
            print("[COMPRESS] Compressed to \(sizeKB)KB at \(Int(compression * 100))% quality")
        }
        
        return imageData
    }
    
    // MARK: - Convert to Base64
    
    /// Convert image to base64 string for API transmission
    func convertToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}
