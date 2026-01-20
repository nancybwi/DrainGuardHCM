//
//  WeatherVM.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.
//

import SwiftUI

struct WeatherVM {
  var city: String
  var tempC: Int
  var condition: String
  var rainChance: Int
  var updatedAt: String
  var sfSymbol: String
    var summary: String
  static let mock = WeatherVM(
    city: "TP.HCM",
    tempC: 29,
    condition: "Mưa nhẹ",
    rainChance: 70,
    updatedAt: "14:05",
    sfSymbol: "cloud.rain.fill",
    summary: "It's rainning now"
  )
}

private func weatherCard(weather: WeatherVM) -> some View {
  HStack(spacing: 14) {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color.blue.opacity(0.12))
        .frame(width: 56, height: 56)
      Image(systemName: weather.sfSymbol)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(.blue)
    }

    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Text("\(weather.city) • \(weather.updatedAt)")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 10) {
        Text("\(weather.tempC)°")
          .font(.system(size: 28, weight: .bold))
        Text(weather.condition)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      Text("Khả năng mưa: \(weather.rainChance)%")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
    }

    Spacer()

    Button {
      // TODO: open weather detail
    } label: {
      Text("Chi tiết")
        .font(.system(size: 13, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.06))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }
  .padding(16)
  .background(.white.opacity(0.95))
  .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
  .shadow(radius: 8, y: 4)
}
