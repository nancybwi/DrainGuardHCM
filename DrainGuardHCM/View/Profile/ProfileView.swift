//
//  ProfileView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager
    
    // MOCK PROFILE (sau này thay bằng Firestore)
    @State private var fullName: String = "Nguyễn Văn A"
    @State private var username: String = "huytest"
    @State private var phone: String = "0999 999 999"
    @State private var district: String = "Quận 7"
    
    // MOCK SETTINGS
    @State private var allowNotifications: Bool = true
    @State private var shareLocation: Bool = true
    
    // MOCK STATS
    private let statsSent: Int = 12
    private let statsInProgress: Int = 3
    private let statsDone: Int = 8
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    headerCard()
                    
                    statsCard()
                    
                    infoCard()
                    
                    settingsCard()
                    
                    logoutCard()
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .background(Color("main").ignoresSafeArea())
            .navigationTitle("Cá nhân")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    
    private func headerCard() -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fullName)
                    .font(.system(size: 20, weight: .semibold))
                
                Text("@\(username)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                Text(session.userDoc?.email ?? "No email")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 6) {
                    let isAdmin = (session.userDoc?.role == "admin")
                    Image(systemName: isAdmin ? "shield.fill" : "person.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isAdmin ? "Admin" : "User")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.06))
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    // MARK: - Stats
    
    private func statsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thống kê")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 12) {
                statBox(number: statsSent, title: "Đã gửi", icon: "paperplane.fill")
                statBox(number: statsInProgress, title: "Đang xử lý", icon: "clock.fill")
                statBox(number: statsDone, title: "Hoàn thành", icon: "checkmark.seal.fill")
            }
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    private func statBox(number: Int, title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
            Text("\(number)")
                .font(.system(size: 20, weight: .bold))
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Info
    
    private func infoCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin")
                .font(.system(size: 16, weight: .semibold))
            
            infoRow(title: "Số điện thoại", value: phone, icon: "phone.fill")
            infoRow(title: "Khu vực", value: district, icon: "mappin.and.ellipse")
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    private func infoRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 26)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Settings
    
    private func settingsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cài đặt")
                .font(.system(size: 16, weight: .semibold))
            
            toggleRow(
                title: "Thông báo",
                subtitle: "Nhận cập nhật trạng thái report",
                icon: "bell.fill",
                isOn: $allowNotifications
            )
            
            toggleRow(
                title: "Chia sẻ vị trí",
                subtitle: "Gợi ý sewer gần bạn",
                icon: "location.fill",
                isOn: $shareLocation
            )
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    private func toggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 26)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Logout
    
    private func logoutCard() -> some View {
        VStack(spacing: 10) {
            Button {
                session.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Đăng xuất")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}
