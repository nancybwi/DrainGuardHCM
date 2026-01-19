//
//  SessionManager.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SessionManager: ObservableObject {

    enum AuthState {
        case loading
        case loggedOut
        case loggedInUser
        case loggedInAdmin
    }

    @Published var state: AuthState = .loading

    private var handle: AuthStateDidChangeListenerHandle?

    func listenAuth() {
        if handle != nil { return }

        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                if user == nil {
                    self.state = .loggedOut
                } else {
                    self.state = .loading
                    await self.loadRoleAndRoute()
                }
            }
        }
    }

    private func loadRoleAndRoute() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            state = .loggedOut
            return
        }

        do {
            let doc = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            let role = (doc.data()?["role"] as? String) ?? "user"

            if role == "admin" {
                state = .loggedInAdmin
            } else {
                state = .loggedInUser
            }
        } catch {
            // If role fetch fails, safest fallback is logged out or user.
            print("⚠️ Failed to load user role: \(error.localizedDescription)")
            state = .loggedInUser  // Default to user instead of logged out
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        state = .loggedOut
    }
}

