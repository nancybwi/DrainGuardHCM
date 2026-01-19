//
//  NavBar.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI
import FirebaseAuth

struct NavBar: View {
    @State private var selection = 0 // Start on Home tab
    @State private var showReportFlow = false // Start report flow
    
    // Sample reports for StatusView (will be replaced with real data from Firestore)
    @State private var sampleReports: [Report] = []
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("main").ignoresSafeArea()
                
                // Main Content Area
                Group {
                    switch selection {
                    case 0:
                        HomeView()
                    case 1:
                        MapView(hazards: sampleHazards)
                    case 2:
                        StatusView(reports: sampleReports)
                    case 3:
                        ProfileView()
                    default:
                        HomeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                customTabBar()
            }
            .onAppear {
                loadSampleReports()
            }
            // Report Flow: Camera → Map → Confirm → Submit
            .navigationDestination(isPresented: $showReportFlow) {
                ReportFlowCameraView()
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    
    @ViewBuilder
    private func customTabBar() -> some View {
        ZStack {
            // Tab Bar Background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
                .frame(height: 92)
                .padding(.horizontal, 18)
            
            // Tab Items
            HStack(spacing: 0) {
                navTab(index: 0, icon: "house", iconFill: "house.fill", title: "Home")
                navTab(index: 1, icon: "map", iconFill: "map.fill", title: "Map")
                
                Spacer().frame(width: 80) // Space for floating button
                
                navTab(index: 2, icon: "chart.bar", iconFill: "chart.bar.fill", title: "Status")
                navTab(index: 3, icon: "person", iconFill: "person.fill", title: "Profile")
            }
            .padding(.horizontal, 28)
            .frame(height: 92)
            
            // Floating Report Button - Starts report flow
            Button {
                showReportFlow = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brown, Color.brown.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: .brown.opacity(0.4), radius: 12, y: 6)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -40)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: selection)
    }
    
    // MARK: - Tab Item
    
    @ViewBuilder
    private func navTab(index: Int, icon: String, iconFill: String, title: String) -> some View {
        let isSelected = (selection == index)
        
        Button {
            selection = index
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.brown.opacity(0.12))
                            .frame(width: 48, height: 36)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: isSelected ? iconFill : icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .brown : .gray)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                
                Text(title)
                    .font(.custom("BubblerOne-Regular", size: 13))
                    .foregroundColor(isSelected ? .brown : .gray)
                    .opacity(isSelected ? 1 : 0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Load Sample Data
    
    private func loadSampleReports() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // TODO: Replace with Firestore query in next sprint
        sampleReports = [
            Report(
                id: "report_001",
                userId: userId,
                drainId: "drain_nguyen_hue",
                drainTitle: "Drain near Nguyen Hue Walking Street",
                drainLatitude: 10.728979,
                drainLongitude: 106.696641,
                imageURL: "",
                description: "Water pooling, trash blocking inlet",
                userSeverity: "High",
                trafficImpact: "Slowing",
                timestamp: Date().addingTimeInterval(-3600),
                reporterLatitude: 10.728950,
                reporterLongitude: 106.696620,
                locationAccuracy: 8.5,
                status: "Sent"
            ),
            Report(
                id: "report_002",
                userId: userId,
                drainId: "drain_le_loi",
                drainTitle: "Drain at Le Loi Boulevard",
                drainLatitude: 10.728956,
                drainLongitude: 106.696412,
                imageURL: "",
                description: "Partially blocked by leaves",
                userSeverity: "Medium",
                trafficImpact: "Normal",
                timestamp: Date().addingTimeInterval(-86400),
                reporterLatitude: 10.728930,
                reporterLongitude: 106.696400,
                locationAccuracy: 12.0,
                isValidated: true,
                aiSeverity: 3,
                aiConfidence: 0.87,
                riskScore: 3.2,
                status: "In Progress",
                assignedTo: "operator_001"
            )
        ]
    }
}

#Preview {
    NavBar()
}
