//
//  StatusView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.

import SwiftUI
import FirebaseAuth

struct StatusView: View {
    @State private var selectedStatus: ReportStatus = .pending
    @StateObject private var reportService = ReportListService()
    
    let userId: String
    let userRole: String
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Title changes based on role
                Text(userRole == "admin" ? "All Reports" : "My Reports")
                    .font(.custom("BubblerOne-Regular", size: 40))
                    .padding(.top)
                
                StatusBarView(selected: $selectedStatus)
                    .padding(.horizontal)
                
                // Loading state
                if reportService.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading reports...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                }
                // Error state
                else if let error = reportService.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("Error loading reports")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                // Content
                else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredReports) { report in
                                if let id = report.id {
                                    NavigationLink {
                                        // Use different detail views based on role
                                        if userRole == "admin" {
                                            AdminReportDetailView(report: report)
                                        } else {
                                            ReportDetailView(report: report)
                                        }
                                    } label: {
                                        StatusCardView(
                                            reportId: id,
                                            title: report.drainTitle,
                                            submittedAt: report.timestamp,
                                            status: report.status,
                                            riskScore: report.riskScore
                                        )
                                    }
                                    .buttonStyle(.plain)
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
                }
                
                Spacer()
            }
        }
        .onAppear {
            print("📊 [StatusView] View appeared - starting listener")
            reportService.startListening(userId: userId, userRole: userRole)
        }
        .onDisappear {
            print("📊 [StatusView] View disappeared - stopping listener")
            reportService.stopListening()
        }
    }
    
    private var filteredReports: [Report] {
        reportService.reports.filter { report in
            report.status == selectedStatus
        }
    }
}

#Preview {
    NavigationStack {
        StatusView(
            userId: "user001",
            userRole: "user"
        )
    }
}
