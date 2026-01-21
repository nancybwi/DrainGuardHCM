//
//  StatusView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
import SwiftUI
import FirebaseAuth

struct StatusView: View {
  @State private var selectedStatus: ReportStatus = .pending
  @EnvironmentObject var reportService: ReportListService

  let userId: String
  let userRole: String

  var body: some View {
    ZStack {
      Color("main").ignoresSafeArea()

      VStack(spacing: 16) {

        // ✅ Localized title
        Text(userRole == "admin" ? "status.title.allReports" : "status.title.myReports")
          .font(.custom("BubblerOne-Regular", size: 40))
          .padding(.top)

        StatusBarView(selected: $selectedStatus)
          .padding(.horizontal)

        if reportService.isLoading {
          VStack(spacing: 12) {
            ProgressView()
              .scaleEffect(1.5)
            Text("status.loading")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxHeight: .infinity)
        }
        else if let error = reportService.error {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 48))
              .foregroundStyle(.red)

            Text("status.error.title")
              .font(.headline)

            Text(error)
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding()
        }
        else {
          ScrollView {
            VStack(spacing: 12) {
              ForEach(filteredReports) { report in
                if let id = report.id {
                  NavigationLink {
                    if userRole == "admin" {
                      AdminReportDetailView(report: report)
                    } else {
                      ReportDetailView(reportId: id, initialReport: report)
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

                  // ✅ Localized empty state (không ghép string kiểu cũ)
                  Text(emptyKey(for: selectedStatus))
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
  }

  private var filteredReports: [Report] {
    reportService.reports.filter { $0.status == selectedStatus }
  }

  // ✅ Return localization key theo status
  private func emptyKey(for status: ReportStatus) -> LocalizedStringKey {
    switch status {
    case .pending: return "status.empty.pending"
    case .inProgress: return "status.empty.inProgress"
    case .done: return "status.empty.done"
    }
  }
}
