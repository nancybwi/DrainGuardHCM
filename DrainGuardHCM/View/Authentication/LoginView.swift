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
  @State private var showPassword = false

  @FocusState private var focusField: Field?
  enum Field { case email, password }

  var body: some View {
    ZStack {
      Color("main").ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 14) {

//          headerCard()
            logoHeader()

          authCard()

        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 24)
      }
    }
  }

  // MARK: - UI Pieces

    private func logoHeader() -> some View {
      VStack(spacing: 12) {

        // Logo
        Image("app_logo") // asset logo của bạn
          .resizable()
          .scaledToFit()
          .frame(width: 150, height: 150)
          .clipShape(Circle())
          .background(
            Circle()
              .fill(.white)
              .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
          )

        // App name
        Text("DrainGuardHCM")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 12)
    }

  private func authCard() -> some View {
    VStack(alignment: .leading, spacing: 14) {

      Text(isRegisterMode ? "auth.register" : "auth.login")
        .font(.system(size: 26, weight: .bold))

      VStack(spacing: 12) {
        // Email
        inputField(
          titleKey: "auth.email",
          systemIcon: "envelope.fill",
          text: $email,
          keyboard: .emailAddress,
          isSecure: false
        )
        .focused($focusField, equals: .email)
        .submitLabel(.next)
        .onSubmit { focusField = .password }

        // Password
        passwordField()
          .focused($focusField, equals: .password)
          .submitLabel(.go)
          .onSubmit { Task { await handleAuth() } }
      }

      if !errorMessage.isEmpty {
        HStack(spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)

          Text(errorMessage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.red)

          Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      Button {
        Task { await handleAuth() }
      } label: {
        HStack(spacing: 10) {
          if isBusy {
            ProgressView().tint(.white)
          } else {
            Image(systemName: isRegisterMode ? "person.badge.plus" : "arrow.right.circle.fill")
              .font(.system(size: 16, weight: .bold))
          }

          Text(isRegisterMode ? "auth.create_account" : "auth.login")
            .font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
          LinearGradient(
            colors: [Color.brown, Color.brown.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .brown.opacity(0.25), radius: 12, y: 6)
      }
      .disabled(isBusy || !canSubmit)
      .opacity((isBusy || !canSubmit) ? 0.65 : 1.0)
      .buttonStyle(.plain)

      Button {
        isRegisterMode.toggle()
        errorMessage = ""
        password = ""
      } label: {
        Text(isRegisterMode ? "auth.have_account_login" : "auth.no_account_register")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.brown)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(Color.brown.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .buttonStyle(.plain)

    }
    .padding(16)
    .background(.white.opacity(0.95))
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(radius: 10, y: 5)
  }

  

  private func inputField(
    titleKey: String,
    systemIcon: String,
    text: Binding<String>,
    keyboard: UIKeyboardType,
    isSecure: Bool
  ) -> some View {
    HStack(spacing: 10) {
      Image(systemName: systemIcon)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.brown)

      if isSecure {
        SecureField(LocalizedStringKey(titleKey), text: text)
          .textInputAutocapitalization(.never)
          .textFieldStyle(.plain)
      } else {
        TextField(LocalizedStringKey(titleKey), text: text)
          .textInputAutocapitalization(.never)
          .keyboardType(keyboard)
          .textFieldStyle(.plain)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(Color.black.opacity(0.04))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.brown.opacity(0.15), lineWidth: 1)
    )
  }

  private func passwordField() -> some View {
    HStack(spacing: 10) {
      Image(systemName: "lock.fill")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.brown)

      if showPassword {
        TextField(LocalizedStringKey("auth.password"), text: $password)
          .textInputAutocapitalization(.never)
          .textFieldStyle(.plain)
      } else {
        SecureField(LocalizedStringKey("auth.password"), text: $password)
          .textFieldStyle(.plain)
      }

      Button {
        showPassword.toggle()
      } label: {
        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(Color.black.opacity(0.04))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.brown.opacity(0.15), lineWidth: 1)
    )
  }

  private var canSubmit: Bool {
    let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
    return !e.isEmpty && password.count >= 6
  }

  // MARK: - Auth

  @MainActor
  private func handleAuth() async {
    errorMessage = ""
    isBusy = true
    defer { isBusy = false }

    let e = email.trimmingCharacters(in: .whitespacesAndNewlines)

    do {
      if isRegisterMode {
        let result = try await Auth.auth().createUser(withEmail: e, password: password)
        try await createUserDoc(uid: result.user.uid, email: e, role: "user")
      } else {
        _ = try await Auth.auth().signIn(withEmail: e, password: password)
      }
    } catch {
      let ns = error as NSError
      print("❌ AUTH/FIRESTORE ERROR:", error)
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
