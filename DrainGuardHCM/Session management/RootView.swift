//
//  RootView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    var body: some View {
        ZStack {
            if !hasSeenWelcome {
                WelcomeView(hasSeenWelcome: $hasSeenWelcome)
            } else {
                switch session.state {
                case .loading:
                    ProgressView()
                case .loggedOut:
                    LoginView()
                case .loggedInUser:
                    NavBar()
                case .loggedInAdmin:
                    NavBar()
                }
            }
        }
        .onAppear { session.listenAuth() }
    }
}
