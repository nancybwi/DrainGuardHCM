//
//  RootView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @State private var showWelcomeView = true

    var body: some View {
        ZStack {
            if showWelcomeView {
                WelcomeView(showWelcomeView: $showWelcomeView)
            } else {
                switch session.state {
                case .loading:
                    ProgressView()
                case .loggedOut:
                    LoginView()
                case .loggedInUser:
                    UserHomeView()
                case .loggedInAdmin:
                    AdminHomeView()
                }
            }
        }
        .onAppear { session.listenAuth() }
    }
}
