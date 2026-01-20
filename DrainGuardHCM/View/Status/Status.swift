//
//  Status.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI

// MARK: - Internal Workflow Status (for logging and internal tracking)

/// Detailed internal status for logging and workflow tracking
enum WorkflowStatus: String {
    case sent = "Sent"                      // Initial submission
    case validating = "Validating"          // AI processing
    case validated = "Validated"            // AI approved
    case rejected = "Rejected"              // AI/Admin rejected
    case assigned = "Assigned"              // Operator assigned
    case inProgress = "In Progress"         // Operator working on it
    case done = "Done"                      // Completed
    
    /// Map internal workflow status to user-facing ReportStatus
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

/// User-facing status saved to Firebase
/// This is what citizens see in the app and what gets saved to Firestore
enum ReportStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "Pending"           // Waiting for validation/assignment
    case inProgress = "In Progress"    // Being worked on by operator
    case done = "Done"                 // Completed and resolved
    
    var id: String { rawValue }
    
    /// User-friendly display name
    var displayName: String {
        rawValue
    }
    
    /// Color coding for status (string format for Report model)
    var color: String {
        switch self {
        case .pending: return "orange"
        case .inProgress: return "purple"
        case .done: return "green"
        }
    }

    /// Color coding for SwiftUI views
    var activeColor: Color {
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .done: return .green
        }
    }
    
    /// Icon for each status
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "wrench.and.screwdriver"
        case .done: return "checkmark.circle.fill"
        }
    }
    
    /// Map old string-based workflow statuses to ReportStatus
    /// Use this when migrating or reading from logs
    static func from(workflowStatus: String) -> ReportStatus {
        switch workflowStatus {
        case "Sent", "Validating":
            return .pending
        case "Validated", "Rejected", "Assigned", "In Progress":
            return .inProgress
        case "Done":
            return .done
        default:
            return .pending // Default to pending for unknown states
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
