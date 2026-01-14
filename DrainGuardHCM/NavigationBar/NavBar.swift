//
//  NavBar.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct NavBar: View {
    @State private var selection = 0

    var body: some View {
        NavigationStack {
            ZStack{
                Color("main").ignoresSafeArea()   // app background
                VStack(spacing: 0) {
                    // Main Content
                    Group {
                        switch selection {
                        case 0: HomeView()
                        case 1: MapView()
                            //                    case 2: AddView()
                            //                    case 3: StatusView()
                            //                    case 4: ProfileView()
                        default: HomeView()
                        }
                    }
                    Spacer()
                    // Custom Tab Bar
                    HStack {
                        VStack {
                            Button(action: { selection = 0 }) {
                                Image("house")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            Text("Home")
                                .font(.custom("BubblerOne-Regular", size: 20))
                                .frame(height: 24)
                        }.frame(maxWidth: .infinity)
                        
                        VStack {
                            Button(action: { selection = 1 }) {
                                Image("map")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            Text("Map")
                                .font(.custom("BubblerOne-Regular", size: 20))
                                .frame(height: 24)
                        }.frame(maxWidth: .infinity)
                        
                        VStack {
                            Button(action: { selection = 2 }) {
                                Image("add")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80)
                            }
                        
                        }.frame(maxWidth: .infinity)
                        
                        VStack {
                            Button(action: { selection = 3 }) {
                                Image("status")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            Text("Status")
                                .font(.custom("BubblerOne-Regular", size: 20))
                                .frame(height: 24)
                        }.frame(maxWidth: .infinity)
                        
                        VStack {
                            Button(action: { selection = 4 }) {
                                Image("profile")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            Text("Profile")
                                .font(.custom("BubblerOne-Regular", size: 20))
                                .frame(height: 24)
                        }.frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: 124)
                    .background(Color.clear)
                }
                .ignoresSafeArea(edges: .bottom)
                
            }
        }
    }
}

#Preview {
    NavBar()
}
