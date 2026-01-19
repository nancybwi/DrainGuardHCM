//
//  ReportSubmit.swift
//  DrainGuardHCM
//
//  Created by Anh Phung on 1/19/26.
//

import SwiftUI
import CoreLocation

struct ReportSubmitView: View {
  let image: UIImage
  let selectedDrain: Drain?

  @StateObject private var locationManager = LocationManager()

  @State private var severity: Severity = .medium
  @State private var drainNearby: DrainNearby = .unsure
  @State private var traffic: TrafficImpact = .slowing

  @State private var isSubmitting = false
  @State private var statusText: String = ""

  var body: some View {
    ZStack {
      Color("main").ignoresSafeArea()
      ScrollView {
        VStack(spacing: 16) {
          Text("Submit report")
            .font(.custom("BubblerOne-Regular", size: 32))

          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 260)
            .cornerRadius(16)

          if let d = selectedDrain {
            Text("Selected: \(d.title)")
              .font(.system(size: 14, weight: .semibold))
          }

          if let coord = locationManager.userLocation {
            Text("Location: \(coord.latitude), \(coord.longitude)")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          } else {
            Text("Getting your location...")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }

          questionCard(title: "A. How bad is it?") {
            Picker("", selection: $severity) {
              ForEach(Severity.allCases) { s in
                Text(s.rawValue).tag(s)
              }
            }
            .pickerStyle(.segmented)
          }

          questionCard(title: "B. Do you see a drain nearby?") {
            Picker("", selection: $drainNearby) {
              ForEach(DrainNearby.allCases) { x in
                Text(x.rawValue).tag(x)
              }
            }
            .pickerStyle(.segmented)
          }

          questionCard(title: "C. Traffic right now?") {
            Picker("", selection: $traffic) {
              ForEach(TrafficImpact.allCases) { t in
                Text(t.rawValue).tag(t)
              }
            }
            .pickerStyle(.segmented)
          }

          Button {
            submit()
          } label: {
            Text(isSubmitting ? "Submitting..." : "Submit")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .disabled(isSubmitting || locationManager.userLocation == nil)

          if !statusText.isEmpty {
            Text(statusText)
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(16)
      }
    }
  }

  @ViewBuilder
  private func questionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title).font(.system(size: 14, weight: .semibold))
      content()
    }
    .padding(12)
    .background(Color.white.opacity(0.85))
    .cornerRadius(14)
  }

  private func submit() {
    isSubmitting = true
    statusText = "Creating report..."

    // TODO: call your Firestore + Storage upload here
    // For now just simulate:
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      isSubmitting = false
      statusText = "Submitted. Waiting for AI validation..."
    }
  }
}


// Mock image so you can preview the UI without using camera.
enum MockImageFactory {
  static func make(width: Int = 900, height: Int = 1200) -> UIImage {
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      UIColor.systemGray5.setFill()
      ctx.fill(CGRect(origin: .zero, size: size))

      let title = "MOCK REPORT"
      let note = "Water pooling on road\nDrain nearby (maybe)\n2026-01-19 11:00 | GPS acc 8m"

      let a1: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 56),
        .foregroundColor: UIColor.black
      ]
      let a2: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 30, weight: .medium),
        .foregroundColor: UIColor.darkGray
      ]

      NSString(string: title).draw(at: CGPoint(x: 50, y: 80), withAttributes: a1)
      NSString(string: note).draw(at: CGPoint(x: 50, y: 170), withAttributes: a2)

      let waterRect = CGRect(x: 70, y: 520, width: size.width - 140, height: 420)
      UIColor.systemBlue.withAlphaComponent(0.20).setFill()
      ctx.fill(waterRect)
      UIColor.systemBlue.withAlphaComponent(0.55).setStroke()
      ctx.stroke(waterRect)

      let drainRect = CGRect(x: 120, y: 980, width: 260, height: 90)
      UIColor.black.withAlphaComponent(0.12).setFill()
      ctx.fill(drainRect)
      UIColor.black.withAlphaComponent(0.25).setStroke()
      ctx.stroke(drainRect)
    }
  }
}

// Mock drain for preview (no need to touch your real sampleHazards).
let previewDrain = Drain(
  title: "Drain near Nguyen Hue",
  coordinate: CLLocationCoordinate2D(latitude: 10.7732, longitude: 106.7033)
)

#Preview {
  ReportSubmitView(
    image: MockImageFactory.make(),
    selectedDrain: previewDrain
  )
}
