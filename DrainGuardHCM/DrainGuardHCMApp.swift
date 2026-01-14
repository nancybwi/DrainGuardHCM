//
//  DrainGuardHCMApp.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

@main
struct DrainGuardHCMApp: App {
    @State private var showWelcomeview: Bool = true
    var body: some Scene {
        WindowGroup {
            if !showWelcomeview{
                NavBar()
            }else{
                WelcomeView(showWelcomeView: $showWelcomeview)
            }
        }
    }
}
