//
//  SessionManager.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 17/1/26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class SessionManager: ObservableObject {
    
    enum AuthState {
        case loading
        case loggedOut
        case loggedInUser
        case loggedInAdmin
    }
    
    @Published var state: AuthState = .loading
    @Published var userDoc: UserDoc? = nil
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    func listenAuth() {
        if handle != nil { return }
        
        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                if user == nil {
                    self.userDoc = nil
                    self.state = .loggedOut
                } else {
                    self.state = .loading
                    await self.loadUserDocAndRoute()
                }
            }
        }
    }
    
    @MainActor
    private func loadUserDocAndRoute() async {
        guard let user = Auth.auth().currentUser else {
            state = .loggedOut
            return
        }
        
        do {
            let snap = try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .getDocument()
            
            let data = snap.data() ?? [:]
            
            let email = (data["email"] as? String) ?? (user.email ?? "")
            let role = (data["role"] as? String) ?? "user"
            
            let fullName = (data["fullName"] as? String) ?? ""
            let username = (data["username"] as? String) ?? ""
            let phone = (data["phone"] as? String) ?? ""
            let district = (data["district"] as? String) ?? ""
            
            self.userDoc = UserDoc(
                uid: user.uid,
                email: email,
                role: role,
                fullName: fullName,
                username: username,
                phone: phone,
                district: district
            )
            
            if role == "admin" {
                state = .loggedInAdmin
            } else {
                state = .loggedInUser
            }
            
        } catch {
            self.userDoc = nil
            state = .loggedOut
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        userDoc = nil
        state = .loggedOut
    }
}
