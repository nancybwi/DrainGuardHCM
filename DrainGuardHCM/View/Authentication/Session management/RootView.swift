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
            // Regular user - sees only their own reports
            if let userDoc = session.userDoc {
                NavBar(
                    userId: userDoc.uid,
                    userRole: userDoc.role
                )
            } else {
                // Fallback if userDoc is nil
                ProgressView()
            }
            
        case .loggedInAdmin:
            // Admin user - sees all reports
            if let userDoc = session.userDoc {
                AdminNavBar(
                    userId: userDoc.uid,
                    userRole: userDoc.role
                )
            } else {
                // Fallback if userDoc is nil
                ProgressView()
            }
        }
    }
}
