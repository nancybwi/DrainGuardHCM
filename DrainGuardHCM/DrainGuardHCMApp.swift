//
//  DrainGuardHCMApp.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct DrainGuardHCMApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = SessionManager()
    @StateObject private var lang = LanguageManager()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    var body: some Scene {
        
        WindowGroup {
            if hasSeenWelcome {
                RootView()
                    .environmentObject(session)
                    .environmentObject(lang)
                    .environment(\.locale, Locale(identifier: lang.appLanguage))
                    .onAppear() {
                        print("✅ App launched")
                        session.listenAuth()
                    }
                
            } else {
                WelcomeView(hasSeenWelcome: $hasSeenWelcome)
            }
        }
    }
}
