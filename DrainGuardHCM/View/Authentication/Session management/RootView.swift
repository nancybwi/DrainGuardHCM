//
//  RootView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var reportService: ReportListService
    
    var body: some View {
        switch session.state {
        case .loading:
            ProgressView()
            
        case .loggedOut:
            LoginView()
                .onAppear {
                    // Stop listener when logged out
                    reportService.stopListening()
                }
            
        case .loggedInUser:
            // Regular user - sees only their own reports
            if let userDoc = session.userDoc {
                NavBar(
                    userId: userDoc.uid,
                    userRole: userDoc.role
                )
                .onAppear {
                    // Start listener when user logs in
                    print("🔥 [RootView] User logged in - starting listener")
                    reportService.startListening(userId: userDoc.uid, userRole: userDoc.role)
                }
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
                .onAppear {
                    // Start listener when admin logs in
                    print("🔥 [RootView] Admin logged in - starting listener")
                    reportService.startListening(userId: userDoc.uid, userRole: userDoc.role)
                }
            } else {
                // Fallback if userDoc is nil
                ProgressView()
            }
        }
    }
}
