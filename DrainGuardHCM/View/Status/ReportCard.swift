//
//  ReportCard.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI

struct StatusCardView: View {
    let reportId: String
    let title: String
    let submittedAt: Date
    let status: String
    let riskScore: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number / ID badge
            Text("#\(reportId.prefix(6))")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.12))
                .foregroundStyle(statusColor)
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
                
                if let risk = riskScore {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(riskColor(risk))
                        Text("Risk: \(String(format: "%.1f", risk))/5.0")
                            .font(.caption2)
                            .foregroundStyle(riskColor(risk))
                    }
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
    
    private var statusColor: Color {
        switch status {
        case "Sent", "Validating": return .orange
        case "Validated", "Assigned": return .blue
        case "In Progress": return .purple
        case "Done": return .green
        case "Rejected": return .red
        default: return .gray
        }
    }
    
    private func riskColor(_ risk: Double) -> Color {
        if risk >= 4.0 { return .red }
        else if risk >= 3.0 { return .orange }
        else { return .yellow }
    }
}

#Preview {
    StatusCardView(
        reportId: "abc123def",
        title: "Clogged drain near Gate 3 (leaves + rubbish)",
        submittedAt: Date(),
        status: "Validated",
        riskScore: 4.2
    )
}
