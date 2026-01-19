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
    @Published var currentUserId: String?
    @Published var currentUserEmail: String?

    private var handle: AuthStateDidChangeListenerHandle?

    func listenAuth() {
        if handle != nil { return }

        print("🔐 [SESSION] Starting auth state listener")
        
        handle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔐 [SESSION] Auth state changed")
                
                if let user = user {
                    print("🔐 [SESSION] User exists in Firebase Auth")
                    print("🔐 [SESSION] User ID: \(user.uid)")
                    print("🔐 [SESSION] Email: \(user.email ?? "no email")")
                    print("🔐 [SESSION] Is anonymous: \(user.isAnonymous)")
                    
                    // ✅ Validate token before allowing access
                    do {
                        let token = try await user.getIDToken(forcingRefresh: true)
                        print("🔐 [SESSION] ✅ Auth token is VALID (length: \(token.count))")
                        
                        self.currentUserId = user.uid
                        self.currentUserEmail = user.email
                        self.state = .loading
                        await self.loadRoleAndRoute()
                    } catch {
                        print("🔐 [SESSION] ❌ Failed to get valid auth token!")
                        print("🔐 [SESSION] Error: \(error.localizedDescription)")
                        
                        if let nsError = error as NSError? {
                            print("🔐 [SESSION] Domain: \(nsError.domain)")
                            print("🔐 [SESSION] Code: \(nsError.code)")
                        }
                        
                        print("🔐 [SESSION] Forcing sign out...")
                        try? Auth.auth().signOut()
                        self.state = .loggedOut
                        self.currentUserId = nil
                        self.currentUserEmail = nil
                    }
                } else {
                    print("🔐 [SESSION] No user - logged out")
                    self.state = .loggedOut
                    self.currentUserId = nil
                    self.currentUserEmail = nil
                }
                
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            }
        }
    }

    private func loadRoleAndRoute() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("🔐 [SESSION] ❌ No current user UID")
            state = .loggedOut
            return
        }

        print("🔐 [SESSION] Loading user role from Firestore...")
        print("🔐 [SESSION] User UID: \(uid)")
        
        do {
            let doc = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            print("🔐 [SESSION] Firestore query completed")
            
            // ✅ Check if document exists
            guard doc.exists else {
                print("🔐 [SESSION] ⚠️ User document does not exist in Firestore!")
                print("🔐 [SESSION] Attempting to create user document...")
                
                // Try to create missing document
                await createMissingUserDocument(uid: uid)
                
                // Default to user role
                print("🔐 [SESSION] Defaulting to user role")
                state = .loggedInUser
                return
            }
            
            let role = (doc.data()?["role"] as? String) ?? "user"
            print("🔐 [SESSION] ✅ User role: \(role)")

            if role == "admin" {
                state = .loggedInAdmin
                print("🔐 [SESSION] State set to: loggedInAdmin")
            } else {
                state = .loggedInUser
                print("🔐 [SESSION] State set to: loggedInUser")
            }
        } catch {
            print("🔐 [SESSION] ❌ Failed to load user role!")
            print("🔐 [SESSION] Error: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                print("🔐 [SESSION] Domain: \(nsError.domain)")
                print("🔐 [SESSION] Code: \(nsError.code)")
                
                // If it's a permission denied error, sign out
                if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
                    print("🔐 [SESSION] Permission denied - forcing sign out")
                    try? Auth.auth().signOut()
                    state = .loggedOut
                    return
                }
            }
            
            // For network errors, allow access with user role
            print("🔐 [SESSION] Defaulting to user role despite error")
            state = .loggedInUser
        }
    }
    
    private func createMissingUserDocument(uid: String) async {
        guard let email = Auth.auth().currentUser?.email else {
            print("🔐 [SESSION] Cannot create user document - no email")
            return
        }
        
        print("🔐 [SESSION] Creating missing user document...")
        print("🔐 [SESSION] Email: \(email)")
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "email": email,
                    "role": "user",
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)
            
            print("🔐 [SESSION] ✅ Created missing user document")
        } catch {
            print("🔐 [SESSION] ❌ Failed to create user document: \(error.localizedDescription)")
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        state = .loggedOut
    }
}

