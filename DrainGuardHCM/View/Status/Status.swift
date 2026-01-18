//
//  Status.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI

enum ReportStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case inProgress = "In progress"
    case done = "Done"

    var id: String { rawValue }

    var activeColor: Color {
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .done: return .green
        }
    }
}

struct StatusBarView: View {
    @Binding var selected: ReportStatus

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ReportStatus.allCases) { status in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selected = status
                    }
                } label: {
                    Text(status.rawValue)
                        .font(.subheadline.weight(status == selected ? .semibold : .regular))
                        .foregroundStyle(status == selected ? status.activeColor : .secondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(status == selected
                                      ? status.activeColor.opacity(0.14)
                                      : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(status == selected
                                        ? status.activeColor.opacity(0.55)
                                        : Color(.separator).opacity(0.35),
                                        lineWidth: status == selected ? 1.5 : 1)
                        )
                        .opacity(status == selected ? 1.0 : 0.45)   // fade the others
                        .scaleEffect(status == selected ? 1.02 : 1.0) // standout
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}
#Preview {
    PreviewStatusBar()
}

private struct PreviewStatusBar: View {
    @State private var status: ReportStatus = .pending

    var body: some View {
        StatusBarView(selected: $status)
            .padding()
    }
}
