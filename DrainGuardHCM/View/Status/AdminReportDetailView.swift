//
//  AdminReportDetailView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import SwiftUI
import MapKit
import FirebaseAuth

struct AdminReportDetailView: View {
  let report: Report
  @Environment(\.dismiss) private var dismiss

  @StateObject private var reportService = ReportService()
  @EnvironmentObject var reportListService: ReportListService

  @State private var isUpdating = false
  @State private var showConfirmation = false
  @State private var actionType: ActionType = .startWork
  @State private var showSuccessMessage = false
  @State private var successMessage = ""

  private var liveReport: Report {
    reportListService.reports.first(where: { $0.id == report.id }) ?? report
  }

  enum ActionType {
    case startWork
    case markDone

    var titleKey: LocalizedStringKey {
      switch self {
      case .startWork: return "adminDetail.action.start.title"
      case .markDone: return "adminDetail.action.done.title"
      }
    }

    var messageKey: LocalizedStringKey {
      switch self {
      case .startWork: return "adminDetail.action.start.message"
      case .markDone: return "adminDetail.action.done.message"
      }
    }

    var buttonKey: LocalizedStringKey {
      switch self {
      case .startWork: return "adminDetail.action.start.button"
      case .markDone: return "adminDetail.action.done.button"
      }
    }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          headerSection
          imageSection
          operatorStatusSection
          locationSection
          userReportSection
          aiValidationSection
          riskAssessmentSection
          locationIntelligenceSection
          nearbyPOIsSection
          operatorWorkflowSection
          timestampSection

          Spacer(minLength: liveReport.status != .done ? 100 : 40)
        }
        .padding()
      }
      .background(Color("main").ignoresSafeArea())

      if liveReport.status != .done {
        adminActionButton
          .padding()
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }

      if showSuccessMessage {
        successBanner
          .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .navigationTitle("adminDetail.navTitle")
    .navigationBarTitleDisplayMode(.inline)
    .alert(actionType.titleKey, isPresented: $showConfirmation) {
      Button("common.cancel", role: .cancel) { }
      Button(actionType.buttonKey) {
        Task { await performAction() }
      }
    } message: {
      Text(actionType.messageKey)
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSuccessMessage)
  }

  // MARK: - Header

  private var headerSection: some View {
    let shortId: String = {
      if let id = liveReport.id { return String(id.prefix(8)) }
      return NSLocalizedString("common.na", comment: "")
    }()

    return VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("adminDetail.header.report")
          + Text(" #\(shortId)")

        Spacer()
        statusBadge
      }
      .font(.custom("BubblerOne-Regular", size: 28))
      .foregroundStyle(.primary)

      Text(liveReport.drainTitle)
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  private var statusBadge: some View {
    Text(statusKey(liveReport.status))
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(liveReport.status.activeColor.opacity(0.15))
      .foregroundStyle(liveReport.status.activeColor)
      .clipShape(Capsule())
  }

  // MARK: - Image

  private var imageSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("adminDetail.section.photoEvidence")
        .font(.headline)

      let displayURL = report.watermarkedImageURL ?? report.imageURL

      if !displayURL.isEmpty {
        AsyncImage(url: URL(string: displayURL)) { phase in
          switch phase {
          case .empty:
            ProgressView()
              .frame(maxWidth: .infinity)
              .frame(height: 250)

          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(maxWidth: .infinity)
              .frame(height: 250)
              .clipShape(RoundedRectangle(cornerRadius: 12))

          case .failure:
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 250)

              VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                  .font(.largeTitle)
                  .foregroundStyle(.secondary)
                Text("common.imageFailed")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

          @unknown default:
            EmptyView()
              .frame(maxWidth: .infinity)
              .frame(height: 250)
          }
        }
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.1))
            .frame(maxWidth: .infinity)
            .frame(height: 250)

          VStack(spacing: 8) {
            Image(systemName: "photo.fill")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("common.noImage")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  // MARK: - Operator Status

  private var operatorStatusSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("adminDetail.section.operatorStatus")
        .font(.headline)

      if let workflow = report.workflowState {
        detailRow(labelKey: "adminDetail.field.workflowState", value: workflow)
      }

      if let assignedTo = report.assignedTo {
        detailRow(labelKey: "adminDetail.field.assignedTo", value: assignedTo)
      }

      if let notes = report.operatorNotes {
        VStack(alignment: .leading, spacing: 4) {
          Text("adminDetail.field.operatorNotes")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(notes)
            .font(.body)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  // MARK: - Location

  private var locationSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("adminDetail.section.location")
        .font(.headline)

      detailRow(labelKey: "adminDetail.field.drainId", value: report.drainId)
      detailRow(
        labelKey: "adminDetail.field.coordinates",
        value: String(format: "%.6f, %.6f", report.drainLatitude, report.drainLongitude)
      )

      Map(initialPosition: .region(
        MKCoordinateRegion(
          center: report.drainLocation,
          span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
      )) {
        Marker(NSLocalizedString("adminDetail.map.drainMarker", comment: ""), coordinate: report.drainLocation)
          .tint(.brown)
      }
      .frame(height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  // MARK: - User Report

  private var userReportSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("adminDetail.section.citizenReport")
        .font(.headline)

      detailRow(labelKey: "adminDetail.field.description", value: report.description)
      detailRow(labelKey: "adminDetail.field.userSeverity", value: report.userSeverity)
      detailRow(labelKey: "adminDetail.field.trafficImpact", value: report.trafficImpact)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  // MARK: - AI Validation

  private var aiValidationSection: some View {
    Group {
      if report.isValidated != nil || report.aiSeverity != nil {
        VStack(alignment: .leading, spacing: 12) {
          Text("adminDetail.section.aiValidation")
            .font(.headline)

          if let validated = report.isValidated {
            detailRow(
              labelKey: "adminDetail.field.validated",
              value: validated ? NSLocalizedString("adminDetail.value.valid", comment: "") : NSLocalizedString("adminDetail.value.invalid", comment: "")
            )
          }

          if let severity = report.aiSeverity {
            detailRow(labelKey: "adminDetail.field.aiSeverity", value: "\(severity)/5")
          }

          if let confidence = report.aiConfidence {
            detailRow(
              labelKey: "adminDetail.field.aiConfidence",
              value: String(format: "%.1f%%", confidence * 100)
            )
          }

          if let issue = report.detectedIssue {
            detailRow(labelKey: "adminDetail.field.detectedIssue", value: issue)
          }

          if let reasons = report.validationReasons, !reasons.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("adminDetail.field.validationReasons")
                .font(.caption)
                .foregroundStyle(.secondary)

              ForEach(reasons, id: \.self) { reason in
                Text("• \(reason)")
                  .font(.body)
              }
            }
          }

          if let rejection = report.validationRejectionReason {
            detailRow(labelKey: "adminDetail.field.rejectionReason", value: rejection)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.white)
        )
      }
    }
  }

  // MARK: - Risk Assessment

  private var riskAssessmentSection: some View {
    Group {
      if let risk = report.riskScore {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("adminDetail.section.riskAssessment")
              .font(.headline)

            Spacer()

            Text(String(format: "%.1f/5.0", risk))
              .font(.title2.weight(.bold))
              .foregroundStyle(riskColor(risk))
          }

          HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { level in
              RoundedRectangle(cornerRadius: 4)
                .fill(Double(level) <= risk ? riskColor(risk) : Color.gray.opacity(0.2))
                .frame(height: 8)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.white)
        )
      }
    }
  }

  // MARK: - Location Intelligence

  private var locationIntelligenceSection: some View {
    Group {
      if report.nearSchool != nil || report.nearHospital != nil {
        VStack(alignment: .leading, spacing: 12) {
          Text("adminDetail.section.locationIntelligence")
            .font(.headline)

          if let nearSchool = report.nearSchool {
            HStack {
              Image(systemName: nearSchool ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(nearSchool ? .green : .gray)
              Text("adminDetail.field.nearSchool")
              Spacer()
              if let distance = report.distanceToSchool {
                Text("\(Int(distance))m")
                  .foregroundStyle(.secondary)
              }
            }
          }

          if let nearHospital = report.nearHospital {
            HStack {
              Image(systemName: nearHospital ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(nearHospital ? .green : .gray)
              Text("adminDetail.field.nearHospital")
              Spacer()
              if let distance = report.distanceToHospital {
                Text("\(Int(distance))m")
                  .foregroundStyle(.secondary)
              }
            }
          }

          if let rushHour = report.submittedDuringRushHour {
            HStack {
              Image(systemName: rushHour ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(rushHour ? .orange : .gray)
              Text("adminDetail.field.rushHourSubmission")
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.white)
        )
      }
    }
  }

  // MARK: - Nearby POIs

  private var nearbyPOIsSection: some View {
    Group {
      if let pois = report.nearbyPOIs, !pois.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("adminDetail.section.nearbyPOIs")
            .font(.headline)

          ForEach(pois, id: \.self) { poi in
            HStack {
              Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.brown)
              Text(poi)
                .font(.body)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.white)
        )
      }
    }
  }

  // MARK: - Operator Workflow

  private var operatorWorkflowSection: some View {
    Group {
      if report.completedAt != nil || report.afterImageURL != nil {
        VStack(alignment: .leading, spacing: 12) {
          Text("adminDetail.section.operatorCompletion")
            .font(.headline)

          if let completedAt = report.completedAt {
            detailRow(
              labelKey: "adminDetail.field.completedAt",
              value: completedAt.formatted(date: .long, time: .shortened)
            )
          }

          if let afterURL = report.afterImageURL, !afterURL.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text("adminDetail.field.afterPhoto")
                .font(.caption)
                .foregroundStyle(.secondary)

              AsyncImage(url: URL(string: afterURL)) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                  ZStack {
                    RoundedRectangle(cornerRadius: 12)
                      .fill(Color.gray.opacity(0.1))
                      .frame(maxWidth: .infinity)
                      .frame(height: 200)
                    VStack(spacing: 8) {
                      Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                      Text("common.imageFailed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                  }
                default:
                  ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.white)
        )
      }
    }
  }

  // MARK: - Timestamps

  private var timestampSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("adminDetail.section.timeline")
        .font(.headline)

      detailRow(
        labelKey: "adminDetail.field.submitted",
        value: report.timestamp.formatted(date: .long, time: .shortened)
      )

      if let processedAt = report.aiProcessedAt {
        detailRow(
          labelKey: "adminDetail.field.aiProcessed",
          value: processedAt.formatted(date: .long, time: .shortened)
        )
      }

      if let statusUpdated = report.statusUpdatedAt {
        detailRow(
          labelKey: "adminDetail.field.statusUpdated",
          value: statusUpdated.formatted(date: .long, time: .shortened)
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
  }

  // MARK: - Helper Views

  private func detailRow(labelKey: LocalizedStringKey, value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(labelKey)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.body)
    }
  }

  private func riskColor(_ risk: Double) -> Color {
    if risk >= 4.0 { return .red }
    else if risk >= 3.0 { return .orange }
    else { return .yellow }
  }

  // MARK: - Admin Action Button

  private var adminActionButton: some View {
    Button {
      if liveReport.status == .pending {
        actionType = .startWork
      } else if liveReport.status == .inProgress {
        actionType = .markDone
      }
      showConfirmation = true
    } label: {
      HStack(spacing: 12) {
        if isUpdating {
          ProgressView()
            .tint(.white)
        } else {
          Image(systemName: liveReport.status == .pending ? "play.circle.fill" : "checkmark.circle.fill")
            .font(.title3)

          Text(liveReport.status == .pending ? "adminDetail.button.startWorking" : "adminDetail.button.markDone")
            .font(.headline)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(liveReport.status == .pending ? Color.blue : Color.green)
          .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
      )
      .foregroundColor(.white)
    }
    .disabled(isUpdating)
    .opacity(isUpdating ? 0.6 : 1.0)
  }

  // MARK: - Success Banner

  private var successBanner: some View {
    VStack {
      HStack(spacing: 12) {
        Image(systemName: "checkmark.circle.fill")
          .font(.title2)
          .foregroundColor(.white)

        Text(successMessage)
          .font(.subheadline.weight(.medium))
          .foregroundColor(.white)

        Spacer()
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.green)
          .shadow(radius: 8)
      )
      .padding(.horizontal)
      .padding(.top, 8)

      Spacer()
    }
  }

  // MARK: - Perform Action

  private func performAction() async {
    guard let reportId = report.id else {
      print("❌ [ACTION] No report ID available")
      return
    }

    isUpdating = true

    do {
      let newStatus: ReportStatus
      let assignedTo: String?

      if actionType == .startWork {
        newStatus = .inProgress
        assignedTo = Auth.auth().currentUser?.uid ?? "admin"
        successMessage = NSLocalizedString("adminDetail.success.startWork", comment: "")
      } else {
        newStatus = .done
        assignedTo = nil
        successMessage = NSLocalizedString("adminDetail.success.markDone", comment: "")
      }

      print("🎯 [ACTION] Updating report \(reportId) to \(newStatus.rawValue)")

      try await reportService.updateReportStatus(
        reportId: reportId,
        newStatus: newStatus,
        assignedTo: assignedTo
      )

      print("✅ [ACTION] Status updated successfully")

      withAnimation {
        showSuccessMessage = true
      }

      try? await Task.sleep(nanoseconds: 2_000_000_000)

      withAnimation {
        showSuccessMessage = false
      }

      try? await Task.sleep(nanoseconds: 500_000_000)
      dismiss()

    } catch {
      print("❌ [ACTION] Failed to update status: \(error.localizedDescription)")
    }

    isUpdating = false
  }

  // MARK: - Status localization helpers

  private func statusKey(_ status: ReportStatus) -> LocalizedStringKey {
    switch status {
    case .pending: return "status.pending"
    case .inProgress: return "status.inProgress"
    case .done: return "status.done"
    }
  }
}

#Preview {
  NavigationStack {
    AdminReportDetailView(
      report: Report(
        id: "abc123",
        userId: "user001",
        drainId: "WVk9mgVkTXPMH8mCeVFX",
        drainTitle: "Crescent Mall Area",
        drainLatitude: 10.730547,
        drainLongitude: 106.717834,
        imageURL: "https://example.com/image.jpg",
        description: "ok",
        userSeverity: "Medium",
        trafficImpact: "Slowing",
        timestamp: Date(),
        reporterLatitude: 10.729482,
        reporterLongitude: 106.696413,
        locationAccuracy: 27.91,
        status: .pending
      )
    )
    .environmentObject(ReportListService())
  }
}
