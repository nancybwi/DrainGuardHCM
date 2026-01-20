//
//  AdminReportDetailView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import SwiftUI
import MapKit
import FirebaseAuth

struct AdminReportDetailView: View {
    let report: Report
    @Environment(\.dismiss) private var dismiss
    
    // Service for updating report status
    @StateObject private var reportService = ReportService()
    
    // Service for real-time updates
    @EnvironmentObject var reportListService: ReportListService
    
    // State for action buttons
    @State private var isUpdating = false
    @State private var showConfirmation = false
    @State private var actionType: ActionType = .startWork
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Real-time report data
    private var liveReport: Report {
        reportListService.reports.first(where: { $0.id == report.id }) ?? report
    }
    
    enum ActionType {
        case startWork
        case markDone
        
        var title: String {
            switch self {
            case .startWork: return "Start Working?"
            case .markDone: return "Mark as Done?"
            }
        }
        
        var message: String {
            switch self {
            case .startWork: return "This will move the report to In Progress and assign it to you."
            case .markDone: return "This will mark the report as completed."
            }
        }
        
        var buttonText: String {
            switch self {
            case .startWork: return "Start"
            case .markDone: return "Complete"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with report ID
                    headerSection
                    
                    // Image Section (watermarked if available)
                    imageSection
                    
                    // Status Section
                    operatorStatusSection
                    
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
                    
                    // Operator Workflow Information
                    operatorWorkflowSection
                    
                    // Timestamps
                    timestampSection
                    
                    // Add space for floating button
                    Spacer(minLength: liveReport.status != .done ? 100 : 40)
                }
                .padding()
            }
            .background(Color("main").ignoresSafeArea())
            
            // Floating action button (only show if not done)
            if liveReport.status != .done {
                adminActionButton
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Success message overlay
            if showSuccessMessage {
                successBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(actionType.title, isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(actionType.buttonText) {
                Task {
                    await performAction()
                }
            }
        } message: {
            Text(actionType.message)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSuccessMessage)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Report #\(liveReport.id?.prefix(8) ?? "N/A")")
                    .font(.custom("BubblerOne-Regular", size: 28))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                statusBadge
            }
            
            Text(liveReport.drainTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    private var statusBadge: some View {
        Text(liveReport.status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(liveReport.status.activeColor.opacity(0.15))
            .foregroundStyle(liveReport.status.activeColor)
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
    
    // MARK: - Operator Status
    private var operatorStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Operator Status Information")
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
    
    // MARK: - Operator Workflow
    private var operatorWorkflowSection: some View {
        Group {
            if report.completedAt != nil || report.afterImageURL != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Operator Completion Details")
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
    
    // MARK: - Admin Action Button
    
    private var adminActionButton: some View {
        Button {
            // Determine action based on current status
            if liveReport.status == .pending {
                actionType = .startWork
            } else if liveReport.status == .inProgress {
                actionType = .markDone
            }
            showConfirmation = true
        } label: {
            HStack(spacing: 12) {
                if isUpdating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: liveReport.status == .pending ? "play.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                    Text(liveReport.status == .pending ? "Start Working" : "Mark as Done")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(liveReport.status == .pending ? Color.blue : Color.green)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
            .foregroundColor(.white)
        }
        .disabled(isUpdating)
        .opacity(isUpdating ? 0.6 : 1.0)
    }
    
    // MARK: - Success Banner
    
    private var successBanner: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(successMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
                    .shadow(radius: 8)
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Perform Action
    
    private func performAction() async {
        guard let reportId = report.id else {
            print("❌ [ACTION] No report ID available")
            return
        }
        
        isUpdating = true
        
        do {
            let newStatus: ReportStatus
            let assignedTo: String?
            
            if actionType == .startWork {
                newStatus = .inProgress
                // Get current admin user ID
                assignedTo = Auth.auth().currentUser?.uid ?? "admin"
                successMessage = "Report assigned to you and moved to In Progress"
            } else {
                newStatus = .done
                assignedTo = nil
                successMessage = "Report marked as completed"
            }
            
            print("🎯 [ACTION] Updating report \(reportId) to \(newStatus.rawValue)")
            
            try await reportService.updateReportStatus(
                reportId: reportId,
                newStatus: newStatus,
                assignedTo: assignedTo
            )
            
            print("✅ [ACTION] Status updated successfully")
            
            // Show success message
            withAnimation {
                showSuccessMessage = true
            }
            
            // Auto-hide success message after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            withAnimation {
                showSuccessMessage = false
            }
            
            // Navigate back after brief delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            dismiss()
            
        } catch {
            print("❌ [ACTION] Failed to update status: \(error.localizedDescription)")
            // Could show error alert here
        }
        
        isUpdating = false
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
        .environmentObject(ReportListService())
    }
}
