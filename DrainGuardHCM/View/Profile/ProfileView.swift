//
//  ProfileView.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.
import SwiftUI

struct ProfileView: View {
  @EnvironmentObject var session: SessionManager
  @EnvironmentObject var lang: LanguageManager

  @State private var fullName: String = "Nguyễn Văn A"
  @State private var username: String = "huytest"
  @State private var phone: String = "0999 999 999"
  @State private var district: String = "Quận 7"

  @State private var allowNotifications: Bool = true
  @State private var shareLocation: Bool = true

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
      .navigationTitle("profile.title")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

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

          if let email = session.userDoc?.email {
            Text(email)
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
          } else {
            Text("profile.no_email")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
          }
          
          HStack(spacing: 6) {
          let isAdmin = (session.userDoc?.role == "admin")
          Image(systemName: isAdmin ? "shield.fill" : "person.fill")
            .font(.system(size: 12, weight: .semibold))
          Text(isAdmin ? "profile.role_admin" : "profile.role_user")
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

  private func statsCard() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("profile.stats")
        .font(.system(size: 16, weight: .semibold))

      HStack(spacing: 12) {
        statBox(number: statsSent, titleKey: "profile.stats_sent", icon: "paperplane.fill")
        statBox(number: statsInProgress, titleKey: "profile.stats_in_progress", icon: "clock.fill")
        statBox(number: statsDone, titleKey: "profile.stats_done", icon: "checkmark.seal.fill")
      }
    }
    .padding(16)
    .background(.white.opacity(0.9))
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(radius: 8, y: 4)
  }

    private func statBox(number: Int, titleKey: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
      Text("\(number)")
        .font(.system(size: 20, weight: .bold))
      Text(titleKey)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.black.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func infoCard() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("profile.info")
        .font(.system(size: 16, weight: .semibold))

      infoRow(titleKey: "profile.phone", value: phone, icon: "phone.fill")
      infoRow(titleKey: "profile.district", value: district, icon: "mappin.and.ellipse")
    }
    .padding(16)
    .background(.white.opacity(0.9))
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(radius: 8, y: 4)
  }

    private func infoRow(titleKey: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .frame(width: 26)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 3) {
        Text(titleKey)
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

  private func settingsCard() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("profile.settings")
        .font(.system(size: 16, weight: .semibold))

      languageRow()

      toggleRow(
        titleKey: "profile.notifications",
        subtitleKey: "profile.notifications_sub",
        icon: "bell.fill",
        isOn: $allowNotifications
      )

      toggleRow(
        titleKey: "profile.share_location",
        subtitleKey: "profile.share_location_sub",
        icon: "location.fill",
        isOn: $shareLocation
      )
    }
    .padding(16)
    .background(.white.opacity(0.9))
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .shadow(radius: 8, y: 4)
  }

  private func languageRow() -> some View {
    HStack(spacing: 12) {
      Image(systemName: "globe")
        .font(.system(size: 16, weight: .semibold))
        .frame(width: 26)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 3) {
        Text("profile.language")
          .font(.system(size: 14, weight: .semibold))

        Text("profile.language_sub")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Picker("", selection: $lang.appLanguage) {
        Text("lang.en").tag("en")
        Text("lang.vi").tag("vi")
      }
      .pickerStyle(.segmented)
      .frame(width: 160)
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .background(Color.black.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

    private func toggleRow(titleKey: LocalizedStringKey, subtitleKey: LocalizedStringKey, icon: String, isOn: Binding<Bool>) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .frame(width: 26)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 3) {
        Text(titleKey)
          .font(.system(size: 14, weight: .semibold))
        Text(subtitleKey)
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

  private func logoutCard() -> some View {
    VStack(spacing: 10) {
      Button {
        session.signOut()
      } label: {
        HStack {
          Image(systemName: "rectangle.portrait.and.arrow.right")
          Text("profile.logout")
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
    .environmentObject(LanguageManager())
}
