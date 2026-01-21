//
//  WeatherVM.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.
//

import SwiftUI

struct WeatherVM {
  var cityKey: LocalizedStringKey
  var tempC: Int
  var conditionKey: LocalizedStringKey
  var rainChance: Int
  var updatedAt: String
  var sfSymbol: String
  var summaryKey: LocalizedStringKey

  static let mock = WeatherVM(
    cityKey: "weather.city.hcm",
    tempC: 29,
    conditionKey: "weather.condition.lightRain",
    rainChance: 70,
    updatedAt: "14:05",
    sfSymbol: "cloud.rain.fill",
    summaryKey: "weather.summary.rainingNow"
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

      // City + updated time
      HStack(spacing: 6) {
        Text(weather.cityKey)
          .font(.system(size: 12, weight: .semibold))
        Text("• \(weather.updatedAt)")
          .font(.system(size: 12, weight: .semibold))
      }
      .foregroundStyle(.secondary)

      // Temperature + condition
      HStack(spacing: 10) {
        Text("\(weather.tempC)°")
          .font(.system(size: 28, weight: .bold))

        Text(weather.conditionKey)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      // Summary (localized)
      Text(weather.summaryKey)
        .font(.system(size: 13))
        .foregroundStyle(.secondary)

      // Rain chance (localized + %d)
      Text("weather.rainChance \(weather.rainChance)")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
    }

    Spacer()

    Button {
      // TODO: open weather detail
    } label: {
      Text("weather.action.detail")
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
