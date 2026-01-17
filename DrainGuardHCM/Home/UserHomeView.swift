//
//  UserHomeView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import SwiftUI

struct UserHomeView: View {
    @EnvironmentObject var session: SessionManager
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, DrainGuardHCM")
            Button("Logout") {
                session.signOut()
            }
        }
        .padding()
    }
}
