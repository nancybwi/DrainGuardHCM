//
//  ReportCard.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//


import SwiftUI

struct StatusCardView: View {
    let reportId: Int
    let title: String
    let submittedAt: Date
    let status: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Number / ID badge
            Text("#\(reportId)")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(submittedAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    StatusCardView(
        reportId: 1024,
        title: "Clogged drain near Gate 3 (leaves + rubbish)",
      
        submittedAt: Date(),
        status: "Pending",
    )
}
