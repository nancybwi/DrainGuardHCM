//
//  ReportDetailView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 18/1/26.
//

import SwiftUI
import MapKit

struct ReportDetailView: View {
  let reportId: String
  @EnvironmentObject var reportService: ReportListService
  @EnvironmentObject var sessionManager: SessionManager
  @Environment(\.dismiss) private var dismiss

  @State private var region: MKCoordinateRegion
  @State private var showMap = false
  @State private var isUpdatingStatus = false
  @State private var showError = false
  @State private var errorMessage = ""

  private var report: Report? {
    reportService.reports.first(where: { $0.id == reportId })
  }

  init(reportId: String, initialReport: Report) {
    print("📋 [ReportDetail] Initializing with report ID: \(reportId)")
    print("📋 [ReportDetail] Report title: \(initialReport.drainTitle)")
    print("📋 [ReportDetail] Initial status: \(initialReport.status.rawValue)")

    self.reportId = reportId
    _region = State(initialValue: MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: initialReport.drainLatitude,
        longitude: initialReport.drainLongitude
      ),
      span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))
  }

  var body: some View {
    Group {
      if let currentReport = report {
        contentView(for: currentReport)
      } else {
        fallbackView
      }
    }
  }

  private func contentView(for report: Report) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {

        headerSection(report: report)

        statusBanner(report: report)

        if sessionManager.userDoc?.role == "admin" {
          adminStatusButton(report: report)
        }

        imageSection(report: report)

        basicInfoSection(report: report)

        locationSection(report: report)

        if report.riskScore != nil {
          riskScoreSection(report: report)
        }

        descriptionSection(report: report)

        timelineSection(report: report)

        Spacer(minLength: 40)
      }
      .padding()
    }
    .background(Color("main").ignoresSafeArea())
  }

  private var fallbackView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)

      Text("reportDetail.loading")
        .font(.headline)
        .foregroundStyle(.secondary)

      Button("reportDetail.goBack") {
        dismiss()
      }
      .font(.caption)
      .foregroundStyle(.blue)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("main").ignoresSafeArea())
  }

    private func headerSection(report: Report) -> some View {
      let shortId: String = {
        if let id = report.id {
          return String(id.prefix(8))
        }
        return NSLocalizedString("reportDetail.unknown", comment: "")
      }()

      return HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("reportDetail.title")
            .font(.custom("BubblerOne-Regular", size: 28))
            .foregroundStyle(.primary)

          Text("#\(shortId)")
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button { dismiss() } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 28))
            .foregroundStyle(.gray)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
      )
    }

  @ViewBuilder
  private func statusBanner(report: Report) -> some View {
    HStack(spacing: 12) {
      Image(systemName: report.status.icon)
        .font(.system(size: 32))
        .foregroundColor(.white)

      VStack(alignment: .leading, spacing: 4) {
        Text(statusKey(report.status))
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.white)

        Text(statusDescriptionKey(report.status))
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.9))
      }

      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(report.status.activeColor.gradient)
    )
    .shadow(color: report.status.activeColor.opacity(0.3), radius: 8, y: 4)
  }

  private func imageSection(report: Report) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("reportDetail.photoEvidence")
        .font(.headline)
        .foregroundStyle(.primary)

      if !report.imageURL.isEmpty {
        AsyncImage(url: URL(string: report.imageURL)) { phase in
          switch phase {
          case .empty:
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
              ProgressView()
                .scaleEffect(1.5)
            }

          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(maxWidth: .infinity)
              .frame(height: 300)
              .clipShape(RoundedRectangle(cornerRadius: 12))

          case .failure:
            ZStack {
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
              VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                  .font(.system(size: 48))
                  .foregroundStyle(.secondary)
                Text("reportDetail.photoFailed")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

          @unknown default:
            EmptyView()
          }
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
  }

  private func basicInfoSection(report: Report) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("reportDetail.basicInfo")
        .font(.headline)
        .foregroundStyle(.primary)

      infoRow(
        icon: "mappin.circle.fill",
        iconColor: .red,
        label: NSLocalizedString("reportDetail.drainLocation", comment: ""),
        value: report.drainTitle
      )

      Divider()

      infoRow(
        icon: "exclamationmark.triangle.fill",
        iconColor: .orange,
        label: NSLocalizedString("reportDetail.severity", comment: ""),
        value: report.userSeverity
      )

      Divider()

      infoRow(
        icon: "car.fill",
        iconColor: .blue,
        label: NSLocalizedString("reportDetail.trafficImpact", comment: ""),
        value: report.trafficImpact
      )
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
  }

  private func locationSection(report: Report) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("reportDetail.location")
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()

        Button {
          withAnimation {
            showMap.toggle()
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: showMap ? "map.fill" : "map")
            Text(showMap ? "reportDetail.hideMap" : "reportDetail.showMap")
          }
          .font(.caption)
          .foregroundStyle(.blue)
        }
      }

      Text("📍 \(String(format: "%.6f, %.6f", report.drainLatitude, report.drainLongitude))")
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.secondary)

      if showMap {
        Map(initialPosition: .region(
          MKCoordinateRegion(
            center: report.drainLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
          )
        )) {
          Marker(NSLocalizedString("reportDetail.marker.drain", comment: ""), coordinate: report.drainLocation)
            .tint(.red)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
  }

  private func riskScoreSection(report: Report) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("reportDetail.riskAssessment")
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()

        if let risk = report.riskScore {
          Text(String(format: "%.1f/5.0", risk))
            .font(.title2.weight(.bold))
            .foregroundStyle(riskColor(risk))
        }
      }

      if let risk = report.riskScore {
        HStack(spacing: 4) {
          ForEach(1...5, id: \.self) { level in
            RoundedRectangle(cornerRadius: 4)
              .fill(Double(level) <= risk ? riskColor(risk) : Color.gray.opacity(0.2))
              .frame(height: 8)
          }
        }

        HStack {
          Image(systemName: "info.circle.fill")
            .foregroundStyle(riskColor(risk))
          Text(riskDescriptionKey(risk))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
  }

  private func descriptionSection(report: Report) -> some View {
    card {
      VStack(alignment: .leading, spacing: 12) {
        Text("reportDetail.description")
          .font(.headline)
          .foregroundStyle(.primary)

        if !report.description.isEmpty {
          Text(report.description)
            .font(.body)
            .foregroundStyle(.primary)
        } else {
          Text("reportDetail.noDescription")
            .font(.body)
            .foregroundStyle(.secondary)
            .italic()
        }
      }
    }
  }

  private func timelineSection(report: Report) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("reportDetail.timeline")
        .font(.headline)
        .foregroundStyle(.primary)

      infoRow(
        icon: "clock.fill",
        iconColor: .blue,
        label: NSLocalizedString("reportDetail.submitted", comment: ""),
        value: report.timestamp.formatted(date: .abbreviated, time: .shortened)
      )

      if let statusUpdated = report.statusUpdatedAt {
        Divider()
        infoRow(
          icon: "clock.arrow.circlepath",
          iconColor: .purple,
          label: NSLocalizedString("reportDetail.lastUpdated", comment: ""),
          value: statusUpdated.formatted(date: .abbreviated, time: .shortened)
        )
      }

      if let completed = report.completedAt {
        Divider()
        infoRow(
          icon: "checkmark.circle.fill",
          iconColor: .green,
          label: NSLocalizedString("reportDetail.completed", comment: ""),
          value: completed.formatted(date: .abbreviated, time: .shortened)
        )
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
  }

  @ViewBuilder
  private func adminStatusButton(report: Report) -> some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "shield.checkered")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.blue)

        Text("reportDetail.adminControls")
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()
      }

      Button {
        updateReportStatus(report: report)
      } label: {
        HStack(spacing: 12) {
          if isUpdatingStatus {
            ProgressView()
              .scaleEffect(0.9)
          } else {
            Image(systemName: nextStatusIcon(for: report.status))
              .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
              Text(nextStatusActionKey(for: report.status))
                .font(.system(size: 16, weight: .semibold))

              Text("reportDetail.currentStatus \(statusKey(report.status))")
                .font(.caption)
                .opacity(0.8)
            }
          }

          Spacer()

          if !isUpdatingStatus {
            Image(systemName: "arrow.right.circle.fill")
              .font(.system(size: 20))
          }
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(nextStatusColor(for: report.status).gradient)
        )
      }
      .disabled(isUpdatingStatus || report.status == .done)
      .opacity(report.status == .done ? 0.5 : 1.0)

      if report.status == .done {
        HStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
          Text("reportDetail.alreadyCompleted")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    )
    .alert("reportDetail.errorTitle", isPresented: $showError) {
      Button("reportDetail.ok", role: .cancel) { }
    } message: {
      Text(errorMessage)
    }
  }

  private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundStyle(iconColor)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(value)
          .font(.body)
          .foregroundStyle(.primary)
      }
    }
  }

  private func riskColor(_ risk: Double) -> Color {
    if risk >= 4.0 { return .red }
    else if risk >= 3.0 { return .orange }
    else if risk >= 2.0 { return .yellow }
    else { return .green }
  }

  private func riskDescriptionKey(_ risk: Double) -> LocalizedStringKey {
    if risk >= 4.0 { return "reportDetail.risk.critical" }
    else if risk >= 3.0 { return "reportDetail.risk.high" }
    else if risk >= 2.0 { return "reportDetail.risk.medium" }
    else { return "reportDetail.risk.low" }
  }

  private func statusKey(_ status: ReportStatus) -> LocalizedStringKey {
    switch status {
    case .pending: return "status.pending"
    case .inProgress: return "status.inProgress"
    case .done: return "status.done"
    }
  }

  private func statusDescriptionKey(_ status: ReportStatus) -> LocalizedStringKey {
    switch status {
    case .pending:
      return "reportDetail.statusDesc.pending"
    case .inProgress:
      return "reportDetail.statusDesc.inProgress"
    case .done:
      return "reportDetail.statusDesc.done"
    }
  }

  private func nextStatus(for currentStatus: ReportStatus) -> ReportStatus {
    switch currentStatus {
    case .pending:
      return .inProgress
    case .inProgress:
      return .done
    case .done:
      return .done
    }
  }

  private func nextStatusActionKey(for currentStatus: ReportStatus) -> LocalizedStringKey {
    switch currentStatus {
    case .pending:
      return "reportDetail.action.startWorking"
    case .inProgress:
      return "reportDetail.action.markDone"
    case .done:
      return "reportDetail.action.completed"
    }
  }

  private func nextStatusIcon(for currentStatus: ReportStatus) -> String {
    switch currentStatus {
    case .pending:
      return "play.circle.fill"
    case .inProgress:
      return "checkmark.circle.fill"
    case .done:
      return "checkmark.seal.fill"
    }
  }

  private func nextStatusColor(for currentStatus: ReportStatus) -> Color {
    switch currentStatus {
    case .pending:
      return .blue
    case .inProgress:
      return .green
    case .done:
      return .gray
    }
  }

  private func updateReportStatus(report: Report) {
    guard let reportId = report.id else {
      errorMessage = NSLocalizedString("reportDetail.invalidReportId", comment: "")
      showError = true
      return
    }

    let newStatus = nextStatus(for: report.status)
    guard newStatus != report.status else { return }

    isUpdatingStatus = true

    Task {
      do {
        try await reportService.updateReportStatus(reportId: reportId, to: newStatus)
        await MainActor.run {
          isUpdatingStatus = false
        }
      } catch {
        await MainActor.run {
          isUpdatingStatus = false
          errorMessage = error.localizedDescription
          showError = true
        }
      }
    }
  }
}

private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
  content()
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
    )
}
