//
//  ReportDetail.swift
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
        ZStack {
            Color("main").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Close Button
                    HStack {
                        Text("Report Details")
                            .font(.custom("BubblerOne-Regular", size: 32))
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Status Banner
                    statusBanner
                    
                    // Report Image
                    if !report.imageURL.isEmpty {
                        reportImage
                    }
                    
                    // Basic Info Card
                    infoCard
                    
                    // Location Section (Optional)
                    if showMap {
                        locationMap
                    } else {
                        Button {
                            withAnimation {
                                showMap = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Show Location on Map")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Status Banner
    
    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: report.status.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(report.status.displayName)
                    .font(.system(size: 22, weight: .bold))
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
        .shadow(color: report.status.activeColor.opacity(0.4), radius: 10, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Report Image
    
    @ViewBuilder
    private var reportImage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)
            
            AsyncImage(url: URL(string: report.imageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                        
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
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
            .padding(.horizontal)
        }
    }
    
    // MARK: - Info Card
    
    @ViewBuilder
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Report ID
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report ID")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("#\(report.id?.prefix(8) ?? "Unknown")")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                }
            }
            
            Divider()
            
            // Drain Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drain Location")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(report.drainTitle)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            
            Divider()
            
            // Timestamp
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Submitted At")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(report.timestamp, format: .dateTime.day().month().year().hour().minute())
                        .font(.system(size: 16, weight: .medium))
                }
            }
            
            Divider()
            
            // Description
            if !report.description.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "text.alignleft")
                        .foregroundStyle(.purple)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(report.description)
                            .font(.system(size: 16))
                    }
                }
            }
            
            // Risk Score (if available)
            if let risk = report.riskScore {
                Divider()
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(riskColor(risk))
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Risk Score")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f / 5.0", risk))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(riskColor(risk))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Location Map
    
    @ViewBuilder
    private var locationMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.green)
                Text("Location on Map")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button {
                    withAnimation {
                        showMap = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
            
            Map(coordinateRegion: .constant(region), annotationItems: [report]) { report in
                MapMarker(coordinate: CLLocationCoordinate2D(
                    latitude: report.drainLatitude,
                    longitude: report.drainLongitude
                ), tint: .red)
            }
            .frame(height: 250)
            .cornerRadius(12)
            .disabled(true)
            
            Text("📍 \(String(format: "%.6f, %.6f", report.drainLatitude, report.drainLongitude))")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func riskColor(_ risk: Double) -> Color {
        if risk >= 4.0 { return .red }
        else if risk >= 3.0 { return .orange }
        else if risk >= 2.0 { return .yellow }
        else { return .green }
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
            isValidated: true,
            aiSeverity: 4,
            aiConfidence: 0.92,
            aiProcessedAt: Date(),
            riskScore: 4.2,
            riskFactors: nil,
            status: .pending,
            workflowState: "Sent",
            assignedTo: nil,
            statusUpdatedAt: Date(),
            operatorNotes: nil,
            afterImageURL: nil,
            completedAt: nil
        )
    )
}


