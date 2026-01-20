//
//  AdminReportDetailView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import SwiftUI
import MapKit

struct AdminReportDetailView: View {
    let report: Report
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with report ID
                headerSection
                
                // Image Section (watermarked if available)
                imageSection
                
                // Status Section
                statusSection
                
                // Location Section
                locationSection
                
                // Description & User Assessment
                userReportSection
                
                // AI Validation Results
                aiValidationSection
                
                // Risk Assessment
                riskAssessmentSection
                
                // Location Intelligence
                locationIntelligenceSection
                
                // Nearby POIs
                nearbyPOIsSection
                
                // Workflow Information
                workflowSection
                
                // Timestamps
                timestampSection
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color("main").ignoresSafeArea())
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Report #\(report.id?.prefix(8) ?? "N/A")")
                    .font(.custom("BubblerOne-Regular", size: 28))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                statusBadge
            }
            
            Text(report.drainTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    private var statusBadge: some View {
        Text(report.status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(report.status.activeColor.opacity(0.15))
            .foregroundStyle(report.status.activeColor)
            .clipShape(Capsule())
    }
    
    // MARK: - Image
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo Evidence")
                .font(.headline)
            
            // Show watermarked image if available, otherwise original
            let displayURL = report.watermarkedImageURL ?? report.imageURL
            
            if !displayURL.isEmpty {
                AsyncImage(url: URL(string: displayURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(height: 250)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    // MARK: - Status
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Information")
                .font(.headline)
            
            if let workflow = report.workflowState {
                detailRow(label: "Workflow State", value: workflow)
            }
            
            if let assignedTo = report.assignedTo {
                detailRow(label: "Assigned To", value: assignedTo)
            }
            
            if let notes = report.operatorNotes {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Operator Notes:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    // MARK: - Location
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            
            detailRow(label: "Drain ID", value: report.drainId)
            detailRow(
                label: "Coordinates",
                value: String(format: "%.6f, %.6f", report.drainLatitude, report.drainLongitude)
            )
            
            // Mini Map
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: report.drainLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )) {
                Marker("Drain", coordinate: report.drainLocation)
                    .tint(.brown)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    // MARK: - User Report
    private var userReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Citizen Report")
                .font(.headline)
            
            detailRow(label: "Description", value: report.description)
            detailRow(label: "User Severity", value: report.userSeverity)
            detailRow(label: "Traffic Impact", value: report.trafficImpact)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    // MARK: - AI Validation
    private var aiValidationSection: some View {
        Group {
            if report.isValidated != nil || report.aiSeverity != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Validation")
                        .font(.headline)
                    
                    if let validated = report.isValidated {
                        detailRow(
                            label: "Validated",
                            value: validated ? "✅ Valid" : "❌ Invalid"
                        )
                    }
                    
                    if let severity = report.aiSeverity {
                        detailRow(label: "AI Severity", value: "\(severity)/5")
                    }
                    
                    if let confidence = report.aiConfidence {
                        detailRow(
                            label: "AI Confidence",
                            value: String(format: "%.1f%%", confidence * 100)
                        )
                    }
                    
                    if let issue = report.detectedIssue {
                        detailRow(label: "Detected Issue", value: issue)
                    }
                    
                    if let reasons = report.validationReasons, !reasons.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Validation Reasons:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(reasons, id: \.self) { reason in
                                Text("• \(reason)")
                                    .font(.body)
                            }
                        }
                    }
                    
                    if let rejection = report.validationRejectionReason {
                        detailRow(label: "Rejection Reason", value: rejection)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
        }
    }
    
    // MARK: - Risk Assessment
    private var riskAssessmentSection: some View {
        Group {
            if let risk = report.riskScore {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Risk Assessment")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f/5.0", risk))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(riskColor(risk))
                    }
                    
                    // Risk level indicator
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Double(level) <= risk ? riskColor(risk) : Color.gray.opacity(0.2))
                                .frame(height: 8)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
        }
    }
    
    // MARK: - Location Intelligence
    private var locationIntelligenceSection: some View {
        Group {
            if report.nearSchool != nil || report.nearHospital != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location Intelligence")
                        .font(.headline)
                    
                    if let nearSchool = report.nearSchool {
                        HStack {
                            Image(systemName: nearSchool ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(nearSchool ? .green : .gray)
                            Text("Near School")
                            Spacer()
                            if let distance = report.distanceToSchool {
                                Text("\(Int(distance))m")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let nearHospital = report.nearHospital {
                        HStack {
                            Image(systemName: nearHospital ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(nearHospital ? .green : .gray)
                            Text("Near Hospital")
                            Spacer()
                            if let distance = report.distanceToHospital {
                                Text("\(Int(distance))m")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let rushHour = report.submittedDuringRushHour {
                        HStack {
                            Image(systemName: rushHour ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(rushHour ? .orange : .gray)
                            Text("Rush Hour Submission")
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
        }
    }
    
    // MARK: - Nearby POIs
    private var nearbyPOIsSection: some View {
        Group {
            if let pois = report.nearbyPOIs, !pois.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nearby Points of Interest")
                        .font(.headline)
                    
                    ForEach(pois, id: \.self) { poi in
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.brown)
                            Text(poi)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
        }
    }
    
    // MARK: - Workflow
    private var workflowSection: some View {
        Group {
            if report.completedAt != nil || report.afterImageURL != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completion Details")
                        .font(.headline)
                    
                    if let completedAt = report.completedAt {
                        detailRow(
                            label: "Completed At",
                            value: completedAt.formatted(date: .long, time: .shortened)
                        )
                    }
                    
                    if let afterURL = report.afterImageURL, !afterURL.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("After Photo:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            AsyncImage(url: URL(string: afterURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                default:
                                    ProgressView()
                                        .frame(height: 200)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
        }
    }
    
    // MARK: - Timestamps
    private var timestampSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            detailRow(
                label: "Submitted",
                value: report.timestamp.formatted(date: .long, time: .shortened)
            )
            
            if let processedAt = report.aiProcessedAt {
                detailRow(
                    label: "AI Processed",
                    value: processedAt.formatted(date: .long, time: .shortened)
                )
            }
            
            if let statusUpdated = report.statusUpdatedAt {
                detailRow(
                    label: "Status Updated",
                    value: statusUpdated.formatted(date: .long, time: .shortened)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    // MARK: - Helper Views
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
    
    private func riskColor(_ risk: Double) -> Color {
        if risk >= 4.0 { return .red }
        else if risk >= 3.0 { return .orange }
        else { return .yellow }
    }
}

#Preview {
    NavigationStack {
        AdminReportDetailView(
            report: Report(
                id: "abc123",
                userId: "user001",
                drainId: "WVk9mgVkTXPMH8mCeVFX",
                drainTitle: "Crescent Mall Area",
                drainLatitude: 10.730547,
                drainLongitude: 106.717834,
                imageURL: "https://example.com/image.jpg",
                description: "ok",
                userSeverity: "Medium",
                trafficImpact: "Slowing",
                timestamp: Date(),
                reporterLatitude: 10.729482,
                reporterLongitude: 106.696413,
                locationAccuracy: 27.91,
                status: .pending
            )
        )
    }
}
