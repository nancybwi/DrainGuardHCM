//
//  NavBar.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.

import SwiftUI
import FirebaseAuth

struct NavBar: View {
    @State private var selection = 0
    @State private var showReportFlow = false
    
    // User info for role-based access
    let userId: String
    let userRole: String
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("main").ignoresSafeArea()
                
                Group {
                    switch selection {
                    case 0:
                        HomeView()
                    case 1:
                        MapView()
                    case 2:
                        StatusView(userId: userId, userRole: userRole)
                    case 3:
                        ProfileView()
                    default:
                        HomeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                customTabBar()
            }
           
            .navigationDestination(isPresented: $showReportFlow) {
                ReportFlowCameraView(
                    dismissFlow: $showReportFlow,
                    navigateToTab: $selection
                )
            }
        }
    }
    
    @ViewBuilder
    private func customTabBar() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
                .frame(height: 92)
                .padding(.horizontal, 18)
            
            HStack(spacing: 0) {
                navTab(index: 0, icon: "house", iconFill: "house.fill", titleKey: "tab.home")
                navTab(index: 1, icon: "map", iconFill: "map.fill", titleKey: "tab.map")
                
                Spacer().frame(width: 80)
                
                navTab(index: 2, icon: "chart.bar", iconFill: "chart.bar.fill", titleKey: "tab.status")
                navTab(index: 3, icon: "person", iconFill: "person.fill", titleKey: "tab.profile")
            }
            .padding(.horizontal, 28)
            .frame(height: 92)
            
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
    
    @ViewBuilder
    private func navTab(index: Int, icon: String, iconFill: String, titleKey: String) -> some View {
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
                
                Text(LocalizedStringKey(titleKey))
                    .font(.custom("BubblerOne-Regular", size: 13))
                    .foregroundColor(isSelected ? .brown : .gray)
                    .opacity(isSelected ? 1 : 0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
}
