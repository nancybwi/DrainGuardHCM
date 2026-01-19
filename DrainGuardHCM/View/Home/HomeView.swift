//
//  HomeView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct HomeView: View {
    @State private var weather = WeatherVM.mock
    @State private var news: [NewsItem] = NewsItem.mockList
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                headerSection()
                
                floodAlertBanner()
                
                weatherCard(weather: weather)
                
                statsRow()
                
                recentReportsSection()
                
                newsSection(items: news)
                
                quickActionsSection()
                
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(Color("main").ignoresSafeArea())
        .task {
            // MOCK NOW, later replace with real fetch
            // await weather.fetch()
            // await news.fetch()
        }
    }
    
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Xin chào")
                    .font(.system(size: 32, weight: .bold))
                Text("Nguyễn Văn A")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 46, height: 46)
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    private func floodAlertBanner() -> some View {
        ZStack {
            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cảnh báo ngập")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("3 điểm nguy cơ cao gần bạn")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.95))
                }
                
                Spacer()
                
                Button {
                    // TODO: navigate to flood detail/map
                } label: {
                    Text("Xem")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(height: 86)
        .shadow(radius: 8, y: 4)
    }
    
    private func statsRow() -> some View {
        HStack(spacing: 14) {
            statCard(number: "12", title: "Báo cáo đã gửi", tint: .primary)
            statCard(number: "8", title: "Đã hoàn thành", tint: .green)
        }
    }
    
    private func statCard(number: String, title: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
    
    private func recentReportsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Báo cáo gần đây")
                .font(.system(size: 22, weight: .bold))
            
            // TODO: replace with real list
            reportRow(title: "Đường Nguyễn Huệ, Quận 1", date: "18/01/2026", status: .inProgress)
            reportRow(title: "Kênh Nhiêu Lộc, Phường 15", date: "16/01/2026", status: .done)
            reportRow(title: "Đường Lê Lợi, Quận 1", date: "17/01/2026", status: .sent)
        }
    }
    
    private func reportRow(title: String, date: String, status: ReportMiniStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(date)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            status.pill
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 6, y: 3)
    }
    
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hành động nhanh")
                .font(.system(size: 22, weight: .bold))
            
            HStack(spacing: 14) {
                actionCard(title: "Bản đồ ngập", icon: "location.circle.fill", filled: true)
                actionCard(title: "Tìm đường", icon: "paperplane.fill", filled: false)
            }
        }
    }
    
    private func actionCard(title: String, icon: String, filled: Bool) -> some View {
        Button {
            // TODO
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(filled ? Color.blue : .white.opacity(0.95))
            .foregroundStyle(filled ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    
    enum ReportMiniStatus {
        case sent
        case inProgress
        case done

        var pill: some View {
            switch self {
            case .sent:
                return AnyView(pillView(text: "Đã gửi", icon: "clock", bg: Color.blue.opacity(0.18), fg: .blue))
            case .inProgress:
                return AnyView(pillView(text: "Đang xử lý", icon: "exclamationmark.triangle", bg: Color.orange.opacity(0.18), fg: .orange))
            case .done:
                return AnyView(pillView(text: "Hoàn thành", icon: "checkmark.circle", bg: Color.green.opacity(0.18), fg: .green))
            }
        }

        private func pillView(text: String, icon: String, bg: Color, fg: Color) -> some View {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
        }
    }

    private func weatherCard(weather: WeatherVM) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 54, height: 54)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(weather.city)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 10) {
                    Label("\(weather.tempC)°C", systemImage: "thermometer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Label("\(weather.rainChance)%", systemImage: "drop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Text(weather.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 8, y: 4)
    }

    private func newsSection(items: [NewsItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tin tức")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Button("Xem thêm") {
                    // TODO
                }
                .font(.system(size: 14, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            ForEach(items.prefix(3)) { item in
                newsRow(item: item)
            }
        }
    }

    private func newsRow(item: NewsItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 44, height: 44)

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.source)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text(item.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray.opacity(0.7))
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 6, y: 3)
        .onTapGesture {
            // TODO
        }
    
    }
}
