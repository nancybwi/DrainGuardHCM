//
//  UserController.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileController: ObservableObject {
    @Published var profile = Profile(fullName: "", username: "", phone: "", district: "", role: "user")
    @Published var isLoading = false
    @Published var errorText = ""
    
    private let db = Firestore.firestore()
    
    func load() async {
        errorText = ""
        guard let uid = Auth.auth().currentUser?.uid else {
            errorText = "Not logged in"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            let data = doc.data() ?? [:]
            
            profile = Profile(
                fullName: data["fullName"] as? String ?? "",
                username: data["username"] as? String ?? (data["email"] as? String ?? ""),
                phone: data["phone"] as? String ?? "",
                district: data["district"] as? String ?? "",
                role: data["role"] as? String ?? "user"
            )
        } catch {
            errorText = error.localizedDescription
        }
    }
    
    func save() async {
        errorText = ""
        guard let uid = Auth.auth().currentUser?.uid else {
            errorText = "Not logged in"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await db.collection("users").document(uid).setData([
                "fullName": profile.fullName,
                "username": profile.username,
                "phone": profile.phone,
                "district": profile.district,
                "role": profile.role
            ], merge: true)
        } catch {
            errorText = error.localizedDescription
        }
    }
}
