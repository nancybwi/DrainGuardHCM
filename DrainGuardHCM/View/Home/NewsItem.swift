//
//  NewsItem.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 19/1/26.
//

import Foundation
import SwiftUI

struct NewsItem: Identifiable {
  let id = UUID()
  var title: String
  var source: String
  var timeAgo: String
  var sfSymbol: String

  static let mockList: [NewsItem] = [
    NewsItem(title: "Mưa lớn chiều nay, nguy cơ ngập một số tuyến đường", source: "TT Dự báo", timeAgo: "10m", sfSymbol: "cloud.heavyrain.fill"),
    NewsItem(title: "Khuyến cáo tránh khu vực đang thi công cống thoát nước", source: "Sở GTVT", timeAgo: "1h", sfSymbol: "cone.fill"),
    NewsItem(title: "Cập nhật điểm ngập mới tại Quận 1", source: "DrainGuard", timeAgo: "2h", sfSymbol: "exclamationmark.triangle.fill")
  ]
}

private func newsSection(items: [NewsItem]) -> some View {
  VStack(alignment: .leading, spacing: 12) {
    HStack {
      Text("Tin tức & cảnh báo")
        .font(.system(size: 22, weight: .bold))
      Spacer()
      Button("Xem tất cả") {
        // TODO
      }
      .font(.system(size: 13, weight: .bold))
    }

    VStack(spacing: 10) {
      ForEach(items.prefix(3)) { item in
        HStack(spacing: 12) {
          ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(Color.black.opacity(0.06))
              .frame(width: 42, height: 42)
            Image(systemName: item.sfSymbol)
              .font(.system(size: 18, weight: .bold))
              .foregroundStyle(.blue)
          }

          VStack(alignment: .leading, spacing: 5) {
            Text(item.title)
              .font(.system(size: 14, weight: .semibold))
              .lineLimit(2)

            Text("\(item.source) • \(item.timeAgo)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }

          Spacer()

          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 5, y: 3)
      }
    }
  }
}
