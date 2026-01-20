//
//  StatusView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import SwiftUI
import FirebaseAuth

struct StatusView: View {
    @StateObject private var viewModel = StatusViewModel()
    let reports: [Report] // Placeholder - will be replaced by viewModel data
    
    @State private var selectedStatus: ReportStatus = .pending
    @State private var showAllReports = true
    @State private var selectedReport: Report? = nil
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                Text("My Reports")
                    .font(.custom("BubblerOne-Regular", size: 36))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // All Reports Toggle Button
                Button {
                    withAnimation {
                        showAllReports.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showAllReports ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        Text(showAllReports ? "Showing All Reports" : "Filter by Status")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(showAllReports ? .blue : .gray)
                    .padding(.horizontal)
                }
                
                // Status Bar (only show when not showing all)
                if !showAllReports {
                    StatusBarView(selected: $selectedStatus)
                        .padding(.horizontal)
                }
                
                // Reports List
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.reports.isEmpty {
                    emptyStateView
                } else {
                    reportsList
                }
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.fetchReports()
        }
        .refreshable {
            await viewModel.refreshReports()
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let report = selectedReport {
                ReportDetailView(report: report)
            } else {
                VStack {
                    Text("Error: No report selected")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Button("Close") {
                        showDetail = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Reports List
    
    @ViewBuilder
    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredReports) { report in
                    Button {
                        print("📱 [StatusView] Tapped report ID: \(report.id ?? "nil")")
                        selectedReport = report
                        showDetail = true
                    } label: {
                        StatusCardView(
                            reportId: report.id ?? "Unknown",
                            title: report.drainTitle,
                            submittedAt: report.timestamp,
                            status: report.status,
                            riskScore: report.riskScore
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your reports...")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Reports Yet")
                .font(.custom("BubblerOne-Regular", size: 28))
            
            Text("Tap the + button to submit your first drain report")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredReports: [Report] {
        if showAllReports {
            return viewModel.reports
        } else {
            return viewModel.reports.filter { $0.status == selectedStatus }
        }
    }
}

// MARK: - View Model

@MainActor
class StatusViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let reportService = ReportService()
    
    func fetchReports() {
        guard !isLoading else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ [StatusView] No authenticated user")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("📥 [StatusView] Fetching reports for user: \(userId)")
                let fetchedReports = try await reportService.fetchUserReports(userId: userId)
                
                await MainActor.run {
                    self.reports = fetchedReports
                    self.isLoading = false
                    print("✅ [StatusView] Loaded \(fetchedReports.count) reports")
                    
                    // Debug: Print all report IDs
                    for (index, report) in fetchedReports.enumerated() {
                        print("   Report \(index + 1): ID = \(report.id ?? "nil"), Title = \(report.drainTitle)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("❌ [StatusView] Error loading reports: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func refreshReports() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            print("🔄 [StatusView] Refreshing reports...")
            let fetchedReports = try await reportService.fetchUserReports(userId: userId)
            
            await MainActor.run {
                self.reports = fetchedReports
                print("✅ [StatusView] Refreshed \(fetchedReports.count) reports")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("❌ [StatusView] Error refreshing: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    StatusView(reports: [])
}
