//
//  Status.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI

// MARK: - Internal Workflow Status (for logging and internal tracking)

enum WorkflowStatus: String {
  case sent = "Sent"
  case validating = "Validating"
  case validated = "Validated"
  case rejected = "Rejected"
  case assigned = "Assigned"
  case inProgress = "In Progress"
  case done = "Done"

  var toReportStatus: ReportStatus {
    switch self {
    case .sent, .validating:
      return .pending
    case .validated, .rejected, .assigned, .inProgress:
      return .inProgress
    case .done:
      return .done
    }
  }
}

// MARK: - User-Facing Report Status (saved to Firebase)

enum ReportStatus: String, CaseIterable, Identifiable, Codable {
  case pending = "Pending"
  case inProgress = "In Progress"
  case done = "Done"

  var id: String { rawValue }

  // ✅ Localization key cho UI
  var titleKey: LocalizedStringKey {
    switch self {
    case .pending: return "status.tab.pending"
    case .inProgress: return "status.tab.inProgress"
    case .done: return "status.tab.done"
    }
  }

  // ✅ Nếu chỗ nào vẫn cần String (không phải Text), dùng cái này
  var localizedTitleString: String {
    switch self {
    case .pending: return String(localized: "status.tab.pending")
    case .inProgress: return String(localized: "status.tab.inProgress")
    case .done: return String(localized: "status.tab.done")
    }
  }

  // ✅ User-friendly display name (đổi từ rawValue sang localized)
  var displayName: String {
    localizedTitleString
  }

  var color: String {
    switch self {
    case .pending: return "orange"
    case .inProgress: return "purple"
    case .done: return "green"
    }
  }

  var activeColor: Color {
    switch self {
    case .pending: return .orange
    case .inProgress: return .blue
    case .done: return .green
    }
  }

  var icon: String {
    switch self {
    case .pending: return "clock"
    case .inProgress: return "wrench.and.screwdriver"
    case .done: return "checkmark.circle.fill"
    }
  }

  static func from(workflowStatus: String) -> ReportStatus {
    switch workflowStatus {
    case "Sent", "Validating":
      return .pending
    case "Validated", "Rejected", "Assigned", "In Progress":
      return .inProgress
    case "Done":
      return .done
    default:
      return .pending
    }
  }
}

// MARK: - Status Bar View

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
          // ✅ FIX: dùng key thay vì rawValue
          Text(status.titleKey)
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
            .opacity(status == selected ? 1.0 : 0.45)
            .scaleEffect(status == selected ? 1.02 : 1.0)
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
