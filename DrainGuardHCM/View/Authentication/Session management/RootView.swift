//
//  RootView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    
    var body: some View {
        switch session.state {
        case .loading:
            ProgressView()
        case .loggedOut:
            LoginView()
        case .loggedInUser:
            NavBar() // citizen navbar with full features
        case .loggedInAdmin:
            AdminNavBar() // admin navbar with status & profile only
        }
    }
}
