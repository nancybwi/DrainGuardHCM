//
//  AdminNavBar.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 20/1/26.
//

import SwiftUI

struct AdminNavBar: View {
    @State private var selection = 0
    @StateObject private var reportService = ReportListService()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("main").ignoresSafeArea()
                
                Group {
                    switch selection {
                    case 0:
                        StatusView(reports: reportService.reports)
                            .overlay {
                                if reportService.isLoading {
                                    ProgressView("Loading reports...")
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(12)
                                }
                            }
                    case 1:
                        ProfileView()
                    default:
                        StatusView(reports: reportService.reports)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                customTabBar()
            }
            .onAppear {
                reportService.startListening()
            }
            .onDisappear {
                reportService.stopListening()
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
                navTab(index: 0, icon: "chart.bar", iconFill: "chart.bar.fill", titleKey: "tab.status")
                navTab(index: 1, icon: "person", iconFill: "person.fill", titleKey: "tab.profile")
            }
            .padding(.horizontal, 60)
            .frame(height: 92)
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


// ngoại trừ isvalidate, image hash, location accuracy, reporter latitude longlitude, userid, image url, còn lại display hết từ firestore lên
