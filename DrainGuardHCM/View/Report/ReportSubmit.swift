//
//  ReportSubmit.swift
//  DrainGuardHCM
//
//  Created by Anh Phung on 1/19/26.
//

import SwiftUI
import CoreLocation
import FirebaseAuth

struct ReportSubmitView: View {
    let image: UIImage
    let selectedDrain: Drain
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var reportService = ReportServiceCloudinary()  // ← Changed to Cloudinary
    
    @State private var severity: Severity = .medium
    @State private var traffic: TrafficImpact = .slowing
    @State private var description: String = ""
    
    @State private var isSubmitting = false
    @State private var statusText: String = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Submit report")
                        .font(.custom("BubblerOne-Regular", size: 32))
                    
                    // Image Preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(16)
                    
                    // Selected Drain Info
                    drainInfoCard()
                    
                    // Location Info
                    locationInfoCard()
                    
                    // Description Field
                    questionCard(title: "Describe the problem") {
                        TextField("e.g., Water pooling, trash blocking drain...", 
                                  text: $description, 
                                  axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    }
                    
                    // Severity Assessment
                    questionCard(title: "How bad is the blockage?") {
                        Picker("", selection: $severity) {
                            ForEach(Severity.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Traffic Impact
                    questionCard(title: "How is traffic affected?") {
                        Picker("", selection: $traffic) {
                            ForEach(TrafficImpact.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Submit Button
                    Button {
                        submit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Report")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSubmitting || !locationManager.hasLocation || description.isEmpty)
                    
                    // Upload progress bar
                    if isSubmitting && reportService.uploadProgress > 0 {
                        VStack(spacing: 4) {
                            ProgressView(value: reportService.uploadProgress)
                                .tint(.blue)
                            
                            Text("Uploading: \(Int(reportService.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }
                    
                    if !statusText.isEmpty {
                        Text(statusText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Report Submitted!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your report has been validated by AI and successfully submitted!")
        }
        .alert("Submission Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
            Button("Retry") {
                submit()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Get single location when form appears (no continuous tracking needed)
            locationManager.startTracking()
        }
        .onDisappear {
            // Stop tracking when leaving form
            locationManager.stopTracking()
        }
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func drainInfoCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.blue)
                Text("Selected Drain")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            
            Text(selectedDrain.title)
                .font(.system(size: 16, weight: .medium))
            
            if let address = selectedDrain.address {
                Text(address)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            if let district = selectedDrain.district, let ward = selectedDrain.ward {
                Text("\(ward), \(district)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
    }
    
    @ViewBuilder
    private func locationInfoCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                    .foregroundStyle(locationManager.isAuthorized ? .green : .red)
                Text("Your Location")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            
            if let error = locationManager.locationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
            } else if let coord = locationManager.userLocation {
                Text("📍 \(String(format: "%.6f", coord.latitude)), \(String(format: "%.6f", coord.longitude))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                if let accuracy = locationManager.currentAccuracyMeters {
                    HStack(spacing: 4) {
                        Image(systemName: accuracy < 20 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(accuracy < 20 ? .green : .orange)
                        Text("Accuracy: ±\(Int(accuracy))m")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Getting your location...")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
    }
    
    @ViewBuilder
    private func questionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .semibold))
            content()
        }
        .padding(12)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
    }
    
    // MARK: - Submit Logic
    
    private func submit() {
        print("\n")
        print("═══════════════════════════════════════════════════════════")
        print("📝 [UI] SUBMIT BUTTON PRESSED")
        print("═══════════════════════════════════════════════════════════")
        
        guard let userLocation = locationManager.userLocation else {
            print("❌ [UI] ERROR: No user location available")
            statusText = "Error: Location not available"
            return
        }
        
        print("📝 [UI] User location: \(userLocation.latitude), \(userLocation.longitude)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [UI] ERROR: No authenticated user!")
            if let currentUser = Auth.auth().currentUser {
                print("   Current user exists but no UID: \(currentUser)")
            } else {
                print("   No current user at all")
            }
            statusText = "Error: Not authenticated"
            return
        }
        
        print("📝 [UI] User ID: \(userId)")
        print("📝 [UI] Description: \(description)")
        print("📝 [UI] Severity: \(severity.rawValue)")
        print("📝 [UI] Traffic Impact: \(traffic.rawValue)")
        print("📝 [UI] Selected Drain: \(selectedDrain.title)")
        
        isSubmitting = true
        statusText = "Creating report..."
        
        // Create report object (without imageURL initially)
        let report = Report(
            id: nil, // Firestore will auto-generate
            userId: userId,
            drainId: selectedDrain.id ?? UUID().uuidString,
            drainTitle: selectedDrain.title,
            drainLatitude: selectedDrain.latitude,
            drainLongitude: selectedDrain.longitude,
            imageURL: "", // Will be filled by ReportService
            description: description,
            userSeverity: severity.rawValue,
            trafficImpact: traffic.rawValue,
            timestamp: Date(),
            reporterLatitude: userLocation.latitude,
            reporterLongitude: userLocation.longitude,
            locationAccuracy: locationManager.currentAccuracyMeters,
            isValidated: nil,
            aiSeverity: nil,
            aiConfidence: nil,
            aiProcessedAt: nil,
            riskScore: nil,
            riskFactors: nil,
            status: "Sent",
            assignedTo: nil,
            statusUpdatedAt: nil,
            operatorNotes: nil,
            afterImageURL: nil,
            completedAt: nil
        )
        
        print("📝 [UI] Report object created")
        print("📝 [UI] Starting async submission task...")
        
        // Submit to Firebase
        Task {
            do {
                statusText = "Uploading image..."
                
                print("📝 [UI] Calling reportService.submitReport()...")
                let reportId = try await reportService.submitReport(image: image, report: report)
                
                // Success!
                await MainActor.run {
                    isSubmitting = false
                    statusText = "✅ Report submitted successfully!"
                    showSuccess = true
                    print("✅ [UI] SUCCESS! Report submitted with ID: \(reportId)")
                    print("═══════════════════════════════════════════════════════════\n")
                }
                
            } catch {
                // Error handling
                await MainActor.run {
                    isSubmitting = false
                    statusText = "❌ Submission failed"
                    errorMessage = error.localizedDescription
                    showError = true
                    print("❌ [UI] SUBMISSION ERROR: \(error.localizedDescription)")
                    print("❌ [UI] Error type: \(type(of: error))")
                    
                    if let reportError = error as? ReportError {
                        print("❌ [UI] ReportError details: \(reportError.errorDescription ?? "no description")")
                    }
                    
                    print("═══════════════════════════════════════════════════════════\n")
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        ReportSubmitView(
            image: MockImageFactory.make(),
            selectedDrain: sampleHazards[0]
        )
    }
}

// MARK: - Mock Image Factory

enum MockImageFactory {
    static func make(width: Int = 900, height: Int = 1200) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let title = "MOCK REPORT"
            let note = "Water pooling on road\nDrain nearby (maybe)\n2026-01-19 11:00 | GPS acc 8m"
            
            let a1: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 56),
                .foregroundColor: UIColor.black
            ]
            let a2: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            
            NSString(string: title).draw(at: CGPoint(x: 50, y: 80), withAttributes: a1)
            NSString(string: note).draw(at: CGPoint(x: 50, y: 170), withAttributes: a2)
            
            let waterRect = CGRect(x: 70, y: 520, width: size.width - 140, height: 420)
            UIColor.systemBlue.withAlphaComponent(0.20).setFill()
            ctx.fill(waterRect)
            UIColor.systemBlue.withAlphaComponent(0.55).setStroke()
            ctx.stroke(waterRect)
            
            let drainRect = CGRect(x: 120, y: 980, width: 260, height: 90)
            UIColor.black.withAlphaComponent(0.12).setFill()
            ctx.fill(drainRect)
            UIColor.black.withAlphaComponent(0.25).setStroke()
            ctx.stroke(drainRect)
        }
    }
}
