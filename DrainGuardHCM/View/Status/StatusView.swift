//
//  StatusView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//
import SwiftUI
import SwiftUI
import SwiftUI

struct StatusView: View {
    @State private var selectedStatus: ReportStatus = .pending

    // Supply your data here (from database or network)
    let reports: [Report]

    var body: some View {
        VStack(spacing: 16) {
            StatusBarView(selected: $selectedStatus)

            // Show only reports matching selected status
            ForEach(reports.filter { $0.status == selectedStatus }) { report in
                StatusCardView(
                    reportId: report.id,
                    title: report.title,
                    submittedAt: report.submittedAt,
                    status: report.status.rawValue
                )
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Status")
    }
}

#Preview {
    NavigationStack {
        StatusView(
            reports: [
                Report(id: 1024, title: "Clogged drain near Gate 3", submittedAt: Date(), status: .pending),
                Report(id: 1025, title: "Blocked drain near Library", submittedAt: Date(), status: .inProgress),
                Report(id: 1026, title: "Flood near Science building", submittedAt: Date(), status: .done)
            ]
        )
    }
}
