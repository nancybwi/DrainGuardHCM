//
//  NavBar.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//
//
//import SwiftUI
//
//struct NavBar: View {
//    @State private var selection = 0
//
//    var body: some View {
//        NavigationStack {
//            ZStack{
//                Color("main").ignoresSafeArea()   // app background
//                VStack(spacing: 0) {
//                    // Main Content
//                    Group {
//                        switch selection {
//                        case 0: HomeView()
//                        case 1: MapView(hazards: sampleHazards)
//                        case 2: CameraView()
//                            //                    case 3: StatusView()
//                            //                    case 4: ProfileView()
//                        default: HomeView()
//                        }
//                    }
//                    Spacer()
//                    // Custom Tab Bar
//                    HStack {
//                        VStack {
//                            Button(action: { selection = 0 }) {
//                                Image("house")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 60)
//                            }
//                            Text("Home")
//                                .font(.custom("BubblerOne-Regular", size: 20))
//                                .frame(height: 24)
//                        }.frame(maxWidth: .infinity)
//
//                        VStack {
//                            Button(action: { selection = 1 }) {
//                                Image("map")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 60)
//                            }
//                            Text("Map")
//                                .font(.custom("BubblerOne-Regular", size: 20))
//                                .frame(height: 24)
//                        }.frame(maxWidth: .infinity)
//
//                        VStack {
//                            Button(action: { selection = 2 }) {
//                                Image("addIcon")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 80)
//                            }
//
//                        }.frame(maxWidth: .infinity)
//
//                        VStack {
//                            Button(action: { selection = 3 }) {
//                                Image("status")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 60)
//                            }
//                            Text("Status")
//                                .font(.custom("BubblerOne-Regular", size: 20))
//                                .frame(height: 24)
//                        }.frame(maxWidth: .infinity)
//
//                        VStack {
//                            Button(action: { selection = 4 }) {
//                                Image("profile")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 60)
//                            }
//                            Text("Profile")
//                                .font(.custom("BubblerOne-Regular", size: 20))
//                                .frame(height: 24)
//                        }.frame(maxWidth: .infinity)
//                    }
//                    .padding(.horizontal, 20)
//                    .frame(maxHeight: 124)
//                    .background(Color.clear)
//                }
//                .ignoresSafeArea(edges: .bottom)
//
//            }
//        }
//    }
//}
//
//#Preview {
//    NavBar()
import SwiftUI

struct NavBar: View {
    @State private var selection = 0
    @State private var showReport = false
    
    private let sampleReports: [Report] = [
        Report(id: 1024, title: "Đường Nguyễn Huệ, Quận 1", submittedAt: Date(), status: .pending),
        Report(id: 1025, title: "Kênh Nhiêu Lộc, Phường 15", submittedAt: Date(), status: .inProgress),
        Report(id: 1026, title: "Đường Lê Lợi, Quận 1", submittedAt: Date(), status: .done)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("main").ignoresSafeArea()
                
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
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white)
                        .shadow(radius: 10)
                        .frame(height: 92)
                        .padding(.horizontal, 18)
                    
                    HStack {
                        navTab(index: 0, icon: "house", iconFill: "house.fill", title: "Homepage")
                        navTab(index: 1, icon: "map", iconFill: "map.fill", title: "Map")
                        
                        Spacer().frame(width: 56)
                        
                        navTab(index: 2, icon: "chart.bar", iconFill: "chart.bar.fill", title: "Status")
                        navTab(index: 3, icon: "person", iconFill: "person.fill", title: "Profile")
                    }
                    .padding(.horizontal, 28)
                    .frame(height: 92)
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.78), value: selection)
                
                Button {
                    showReport = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 62, height: 62)
                            .shadow(radius: 10)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -36)
            }
        }
        .sheet(isPresented: $showReport) {
            CameraView()
        }
    }
    
    
    
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
                            .frame(width: 44, height: 34)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: isSelected ? iconFill : icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .brown : .gray)
                        .scaleEffect(isSelected ? 1.12 : 1.0)
                }
                
                Text(title)
                    .font(.custom("BubblerOne-Regular", size: 14))
                    .foregroundColor(isSelected ? .brown : .gray)
                    .opacity(isSelected ? 1 : 0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

