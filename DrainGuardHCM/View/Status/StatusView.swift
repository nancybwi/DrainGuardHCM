//
//  StatusView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.

import SwiftUI

struct StatusView: View {
    @State private var selectedStatus: ReportStatus = .pending
    
    // Supply your data here (from database or network)
    let reports: [Report]
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("My Reports")
                    .font(.custom("BubblerOne-Regular", size: 40))
                    .padding(.top)
                
                StatusBarView(selected: $selectedStatus)
                    .padding(.horizontal)
                
                // Filter reports by status
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredReports) { report in
                            if let id = report.id {
                                StatusCardView(
                                    reportId: id,
                                    title: report.drainTitle,
                                    submittedAt: report.timestamp,
                                    status: report.status,
                                    riskScore: report.riskScore
                                )
                            }
                        }
                        
                        if filteredReports.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No \(selectedStatus.rawValue.lowercased()) reports")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
    
    private var filteredReports: [Report] {
        reports.filter { report in
            switch selectedStatus {
            case .pending:
                return report.status == "Sent" || report.status == "Validating"
            case .inProgress:
                return report.status == "Validated" || report.status == "Assigned" || report.status == "In Progress"
            case .done:
                return report.status == "Done"
            }
        }
    }
}

#Preview {
    NavigationStack {
        StatusView(
            reports: [
                Report(
                    id: "abc123",
                    userId: "user001",
                    drainId: "drain1",
                    drainTitle: "Drain near Nguyen Hue Walking Street",
                    drainLatitude: 10.728979,
                    drainLongitude: 106.696641,
                    imageURL: "",
                    description: "Water pooling after rain",
                    userSeverity: "High",
                    trafficImpact: "Slowing",
                    timestamp: Date(),
                    reporterLatitude: 10.728950,
                    reporterLongitude: 106.696620,
                    locationAccuracy: 8.5,
                    status: "Sent"
                ),
                Report(
                    id: "def456",
                    userId: "user001",
                    drainId: "drain2",
                    drainTitle: "Drain at Le Loi Boulevard",
                    drainLatitude: 10.728956,
                    drainLongitude: 106.696412,
                    imageURL: "",
                    description: "Blocked by trash",
                    userSeverity: "Medium",
                    trafficImpact: "Normal",
                    timestamp: Date().addingTimeInterval(-86400),
                    reporterLatitude: 10.728930,
                    reporterLongitude: 106.696400,
                    locationAccuracy: 12.0,
                    status: "In Progress"
                ),
                Report(
                    id: "ghi789",
                    userId: "user001",
                    drainId: "drain3",
                    drainTitle: "Drain near Ben Thanh Market",
                    drainLatitude: 10.772599,
                    drainLongitude: 106.698074,
                    imageURL: "",
                    description: "Fixed last week",
                    userSeverity: "Low",
                    trafficImpact: "Normal",
                    timestamp: Date().addingTimeInterval(-604800),
                    reporterLatitude: 10.772580,
                    reporterLongitude: 106.698060,
                    locationAccuracy: 5.0,
                    riskScore: 2.3,
                    status: "pending",
                    completedAt: Date().addingTimeInterval(-259200)
                )
            ]
        )
    }
}
