//
//  LoginView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
  @EnvironmentObject var session: SessionManager

  @State private var email = ""
  @State private var password = ""
  @State private var isRegisterMode = false
  @State private var errorMessage = ""
  @State private var isBusy = false

  var body: some View {
    VStack(spacing: 16) {
        Text(isRegisterMode ? LocalizedStringKey("auth.register") : LocalizedStringKey("auth.login"))
            .font(.title)

        TextField(LocalizedStringKey("auth.email"), text: $email)
            .textInputAutocapitalization(.never)
        .keyboardType(.emailAddress)
        .textFieldStyle(.roundedBorder)

        SecureField(LocalizedStringKey("auth.password"), text: $password)
            .textFieldStyle(.roundedBorder)

      if !errorMessage.isEmpty {
        Text(errorMessage).foregroundColor(.red)
      }

      Button {
        print("✅ Create account tapped")
        Task { await handleAuth() }
      } label: {
          Text(isRegisterMode ? LocalizedStringKey("auth.create_account") : LocalizedStringKey("auth.login"))
              .frame(maxWidth: .infinity)
      }
      .disabled(isBusy)
      .buttonStyle(.borderedProminent)

      Button {
        isRegisterMode.toggle()
        errorMessage = ""
      } label: {
          Text(isRegisterMode ? LocalizedStringKey("auth.have_account_login") : LocalizedStringKey("auth.no_account_register"))
      }
    }
    .padding()
  }

  @MainActor
  private func handleAuth() async {
    errorMessage = ""
    isBusy = true
    defer { isBusy = false }

    do {
      if isRegisterMode {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        print("Created user uid:", result.user.uid)
        try await createUserDoc(uid: result.user.uid, email: email, role: "user")
      } else {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
      }
    } catch {
      print("❌ AUTH/FIRESTORE ERROR:", error)
      let ns = error as NSError
      print("❌ domain:", ns.domain, "code:", ns.code)
      print("❌ userInfo:", ns.userInfo)
      errorMessage = error.localizedDescription
    }
  }

  private func createUserDoc(uid: String, email: String, role: String) async throws {
    let db = Firestore.firestore()
    try await db.collection("users").document(uid).setData([
      "email": email,
      "role": role == "admin" ? "admin" : "user",
      "fullName": "Nguyễn Văn A",
      "username": "user_\(uid.prefix(6))",
      "phone": "0900 000 000",
      "district": "Quận 7",
      "createdAt": FieldValue.serverTimestamp()
    ], merge: true)
  }
}
