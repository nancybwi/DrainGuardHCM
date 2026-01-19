//
//  AuthStatusDebugView.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Temporary debug view to check authentication status
/// Add this to your app to quickly diagnose auth issues
struct AuthStatusDebugView: View {
    @State private var authStatus: String = "Checking..."
    @State private var userInfo: String = ""
    @State private var tokenInfo: String = ""
    @State private var firestoreInfo: String = ""
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🔍 Auth Status Checker")
                    .font(.title)
                    .bold()
                
                Divider()
                
                // Auth Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Firebase Auth Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(authStatus.contains("✅") ? .green : .red)
                            .frame(width: 12, height: 12)
                        
                        Text(authStatus)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // User Info
                if !userInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User Information")
                            .font(.headline)
                        
                        Text(userInfo)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Token Info
                if !tokenInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auth Token")
                            .font(.headline)
                        
                        Text(tokenInfo)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Firestore Info
                if !firestoreInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Firestore User Document")
                            .font(.headline)
                        
                        Text(firestoreInfo)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        checkAuthStatus()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoading ? "Checking..." : "Check Auth Status")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button {
                        signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isLoading)
                }
            }
            .padding()
        }
        .onAppear {
            checkAuthStatus()
        }
    }
    
    // MARK: - Check Auth Status
    
    private func checkAuthStatus() {
        isLoading = true
        
        Task {
            print("\n🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔍 [DEBUG] AUTH STATUS CHECK STARTED")
            print("🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            // Check if user exists
            guard let user = Auth.auth().currentUser else {
                await MainActor.run {
                    authStatus = "❌ NOT LOGGED IN"
                    userInfo = ""
                    tokenInfo = ""
                    firestoreInfo = ""
                    isLoading = false
                }
                
                print("❌ [DEBUG] No user logged in")
                print("\n🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("🔍 [DEBUG] CHECK COMPLETE")
                print("🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                return
            }
            
            // User exists
            await MainActor.run {
                authStatus = "✅ USER LOGGED IN"
                userInfo = """
                User ID: \(user.uid)
                Email: \(user.email ?? "no email")
                Anonymous: \(user.isAnonymous)
                Verified: \(user.isEmailVerified)
                Created: \(user.metadata.creationDate?.description ?? "unknown")
                """
            }
            
            print("✅ [DEBUG] User logged in")
            print("   User ID: \(user.uid)")
            print("   Email: \(user.email ?? "no email")")
            
            // Check token
            do {
                let token = try await user.getIDToken(forcingRefresh: true)
                
                await MainActor.run {
                    tokenInfo = """
                    Status: ✅ VALID
                    Length: \(token.count) characters
                    Preview: \(token.prefix(30))...
                    """
                }
                
                print("✅ [DEBUG] Auth token is VALID")
                print("   Token length: \(token.count)")
                
            } catch {
                await MainActor.run {
                    tokenInfo = """
                    Status: ❌ INVALID
                    Error: \(error.localizedDescription)
                    """
                }
                
                print("❌ [DEBUG] Auth token is INVALID!")
                print("   Error: \(error.localizedDescription)")
                
                if let nsError = error as NSError? {
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                }
            }
            
            // Check Firestore user document
            do {
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .getDocument()
                
                if doc.exists {
                    let data = doc.data() ?? [:]
                    let role = data["role"] as? String ?? "unknown"
                    let email = data["email"] as? String ?? "unknown"
                    
                    await MainActor.run {
                        firestoreInfo = """
                        Status: ✅ DOCUMENT EXISTS
                        Role: \(role)
                        Email: \(email)
                        Fields: \(data.keys.joined(separator: ", "))
                        """
                    }
                    
                    print("✅ [DEBUG] Firestore user document EXISTS")
                    print("   Role: \(role)")
                    print("   Email: \(email)")
                } else {
                    await MainActor.run {
                        firestoreInfo = """
                        Status: ⚠️ DOCUMENT DOES NOT EXIST
                        This might cause permission issues!
                        """
                    }
                    
                    print("⚠️ [DEBUG] Firestore user document DOES NOT EXIST!")
                }
                
            } catch {
                await MainActor.run {
                    firestoreInfo = """
                    Status: ❌ ERROR FETCHING DOCUMENT
                    Error: \(error.localizedDescription)
                    """
                }
                
                print("❌ [DEBUG] Failed to fetch Firestore user document")
                print("   Error: \(error.localizedDescription)")
                
                if let nsError = error as NSError? {
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            print("\n🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🔍 [DEBUG] CHECK COMPLETE")
            print("🔍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }
    
    // MARK: - Sign Out
    
    private func signOut() {
        print("\n🔐 [DEBUG] Signing out...")
        
        do {
            try Auth.auth().signOut()
            
            authStatus = "✅ Signed out successfully"
            userInfo = ""
            tokenInfo = ""
            firestoreInfo = ""
            
            print("✅ [DEBUG] Signed out successfully")
            
            // Give user 2 seconds to see the message, then reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                checkAuthStatus()
            }
            
        } catch {
            authStatus = "❌ Sign out failed: \(error.localizedDescription)"
            print("❌ [DEBUG] Sign out failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    AuthStatusDebugView()
}

// MARK: - How to Use This View

/*
 
 ## 🔍 How to Add This Debug View to Your App
 
 ### Option 1: Add as a Tab (Temporary)
 
 In your NavBar.swift, add a temporary tab:
 
 ```swift
 TabView {
     // ... existing tabs
     
     // Temporary debug tab
     AuthStatusDebugView()
         .tabItem {
             Label("Debug", systemImage: "ladybug")
         }
 }
 ```
 
 ### Option 2: Add as a Sheet
 
 In your ProfileView or SettingsView:
 
 ```swift
 struct ProfileView: View {
     @State private var showDebug = false
     
     var body: some View {
         VStack {
             // ... existing content
             
             Button("Check Auth Status") {
                 showDebug = true
             }
         }
         .sheet(isPresented: $showDebug) {
             AuthStatusDebugView()
         }
     }
 }
 ```
 
 ### Option 3: Add as a Navigation Link
 
 ```swift
 NavigationLink {
     AuthStatusDebugView()
 } label: {
     Label("Auth Status", systemImage: "shield.checkered")
 }
 ```
 
 ## 📊 What This View Shows
 
 1. **Firebase Auth Status**
    - ✅ Logged in or ❌ Not logged in
 
 2. **User Information**
    - User ID
    - Email
    - Account creation date
 
 3. **Auth Token Status**
    - ✅ Valid or ❌ Invalid
    - Token length
    - Preview of token
 
 4. **Firestore User Document**
    - ✅ Exists or ⚠️ Missing
    - User role
    - Available fields
 
 ## 🎯 How to Use It
 
 1. Add the view to your app (use one of the options above)
 2. Navigate to the debug view
 3. Tap "Check Auth Status" button
 4. Read the output in the view
 5. Check Xcode console for detailed logs
 
 ## ✅ Expected Output (Working)
 
 ```
 Firebase Auth Status: ✅ USER LOGGED IN
 
 User Information:
 User ID: abc123xyz
 Email: user@example.com
 Anonymous: false
 Verified: false
 
 Auth Token:
 Status: ✅ VALID
 Length: 1234 characters
 
 Firestore User Document:
 Status: ✅ DOCUMENT EXISTS
 Role: user
 Email: user@example.com
 ```
 
 ## ❌ Problem Indicators
 
 **If you see:**
 - "❌ NOT LOGGED IN" → Need to log in
 - "❌ INVALID" token → Need to sign out and back in
 - "⚠️ DOCUMENT DOES NOT EXIST" → Missing Firestore user doc (will cause upload issues!)
 - "❌ ERROR FETCHING DOCUMENT" → Firestore rules problem
 
 ## 🔧 Quick Fixes
 
 **Not Logged In:**
 - Tap "Sign Out" button
 - Delete app and clean build
 - Register/login again
 
 **Invalid Token:**
 - Tap "Sign Out" button
 - Log back in
 
 **Missing Firestore Document:**
 - SessionManager should create it automatically
 - Or create manually in Firebase Console → Firestore:
   ```
   Collection: users
   Document ID: [your-user-id]
   Fields:
     email: "your@email.com"
     role: "user"
     createdAt: [timestamp]
   ```
 
 **Firestore Fetch Error:**
 - Check Firestore rules in Firebase Console
 - Make sure users can read their own document
 
 ## 🗑️ Remove After Debugging
 
 This is a temporary debug view. Remove it once you've confirmed:
 - ✅ User is logged in
 - ✅ Token is valid
 - ✅ Firestore user document exists
 - ✅ Report submission works
 
 */
