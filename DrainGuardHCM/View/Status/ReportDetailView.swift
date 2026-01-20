//
//  ReportDetailView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI
import MapKit

struct ReportDetailView: View {
    let report: Report
    @Environment(\.dismiss) private var dismiss
    
    @State private var region: MKCoordinateRegion
    @State private var showMap = false
    
    init(report: Report) {
        print("📋 [ReportDetail] Initializing with report ID: \(report.id ?? "nil")")
        print("📋 [ReportDetail] Report title: \(report.drainTitle)")
        print("📋 [ReportDetail] Report status: \(report.status.rawValue)")
        
        self.report = report
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: report.drainLatitude,
                longitude: report.drainLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with close button
                headerSection
                
                // Status Banner
                statusBanner
                
                // Image Section
                imageSection
                
                // Basic Info
                basicInfoSection
                
                // Location Section
                locationSection
                
                // Risk Score (if available)
                if report.riskScore != nil {
                    riskScoreSection
                }
                
                // Description
                descriptionSection
                
                // Timeline
                timelineSection
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color("main").ignoresSafeArea())
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Report Details")
                    .font(.custom("BubblerOne-Regular", size: 28))
                    .foregroundStyle(.primary)
                
                Text("#\(report.id?.prefix(8) ?? "Unknown")")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                print("📋 [ReportDetail] Close button tapped")
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Status Banner
    
    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: report.status.icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(report.status.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(statusDescription(report.status))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(report.status.activeColor.gradient)
        )
        .shadow(color: report.status.activeColor.opacity(0.3), radius: 8, y: 4)
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Evidence")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if !report.imageURL.isEmpty {
                AsyncImage(url: URL(string: report.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Failed to load image")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Drain Location
            infoRow(
                icon: "mappin.circle.fill",
                iconColor: .red,
                label: "Drain Location",
                value: report.drainTitle
            )
            
            Divider()
            
            // Severity
            infoRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                label: "Severity",
                value: report.userSeverity
            )
            
            Divider()
            
            // Traffic Impact
            infoRow(
                icon: "car.fill",
                iconColor: .blue,
                label: "Traffic Impact",
                value: report.trafficImpact
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Location")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showMap.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showMap ? "map.fill" : "map")
                        Text(showMap ? "Hide Map" : "Show Map")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            
            // Coordinates
            Text("📍 \(String(format: "%.6f, %.6f", report.drainLatitude, report.drainLongitude))")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
            
            // Map (if shown)
            if showMap {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: report.drainLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )) {
                    Marker("Drain", coordinate: report.drainLocation)
                        .tint(.red)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Risk Score Section
    
    private var riskScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Risk Assessment")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let risk = report.riskScore {
                    Text(String(format: "%.1f/5.0", risk))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(riskColor(risk))
                }
            }
            
            // Risk level indicator
            if let risk = report.riskScore {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Double(level) <= risk ? riskColor(risk) : Color.gray.opacity(0.2))
                            .frame(height: 8)
                    }
                }
                
                // Risk description
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(riskColor(risk))
                    Text(riskDescription(risk))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if !report.description.isEmpty {
                Text(report.description)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                Text("No description provided")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Submitted
            infoRow(
                icon: "clock.fill",
                iconColor: .blue,
                label: "Submitted",
                value: report.timestamp.formatted(date: .abbreviated, time: .shortened)
            )
            
            // Status Updated (if available)
            if let statusUpdated = report.statusUpdatedAt {
                Divider()
                infoRow(
                    icon: "clock.arrow.circlepath",
                    iconColor: .purple,
                    label: "Last Updated",
                    value: statusUpdated.formatted(date: .abbreviated, time: .shortened)
                )
            }
            
            // Completed (if available)
            if let completed = report.completedAt {
                Divider()
                infoRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    label: "Completed",
                    value: completed.formatted(date: .abbreviated, time: .shortened)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Helper Views
    
    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func riskColor(_ risk: Double) -> Color {
        if risk >= 4.0 { return .red }
        else if risk >= 3.0 { return .orange }
        else if risk >= 2.0 { return .yellow }
        else { return .green }
    }
    
    private func riskDescription(_ risk: Double) -> String {
        if risk >= 4.0 { return "Critical - High flood risk" }
        else if risk >= 3.0 { return "High - Moderate flood risk" }
        else if risk >= 2.0 { return "Medium - Low flood risk" }
        else { return "Low - Minimal flood risk" }
    }
    
    private func statusDescription(_ status: ReportStatus) -> String {
        switch status {
        case .pending:
            return "Your report is awaiting review"
        case .inProgress:
            return "Maintenance team is working on this"
        case .done:
            return "Issue has been fixed"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReportDetailView(
            report: Report(
                id: "abc123def456",
                userId: "user123",
                drainId: "drain001",
                drainTitle: "Drain near Gate 3, HCMC University",
                drainLatitude: 10.7769,
                drainLongitude: 106.7009,
                imageURL: "https://via.placeholder.com/600x400",
                description: "Severe clogging with leaves and debris blocking water flow. Water pooling on the road.",
                userSeverity: "High",
                trafficImpact: "Slowing",
                timestamp: Date(),
                reporterLatitude: 10.7770,
                reporterLongitude: 106.7010,
                locationAccuracy: 8.5,
                status: .pending
            )
        )
    }
}
