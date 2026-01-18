////
////  Report.swift
////  DrainGuardHCM
////
////  Created by Thao Trinh Phuong on 17/1/26.
////
//
//import SwiftUI
//import _MapKit_SwiftUI
//
//struct DrainReportPayload {
//    let drain: Drain
//    let photo: UIImage
//    let note: String
//    let reporterLocation: CLLocationCoordinate2D?
//    let createdAt: Date
//}
//
//struct Report: View {
//
//    // Inputs (pass these from your “capture photo” screen / previous step)
//    let capturedImage: UIImage
//    let nearbyDrains: [Drain]
//
//    // Location (optional, but matches your acceptance criteria)
//    @StateObject private var locationManager = LocationManager()
//
//    // Form state
//    @State private var note: String = ""
//    @State private var selectedDrain: Drain? = nil
//    @State private var isSubmitting = false
//    @State private var showSuccess = false
//    @State private var errorMessage: String? = nil
//
//    // Map camera
//    @State private var position: MapCameraPosition = .automatic
//    @State private var hasCentredOnUser = false
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                // 1) Photo preview
//                Section("Photo") {
//                    Image(uiImage: capturedImage)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(height: 220)
//                        .clipped()
//                        .cornerRadius(12)
//                }
//
//                // 2) Select drain on map
//                Section("Select the drain on the map") {
//                    ZStack(alignment: .topLeading) {
//                        Map(position: $position) {
//                            // User location pin (optional)
//                            if let userCoord = locationManager.userLocation {
//                                Annotation("You", coordinate: userCoord) {
//                                    Image(systemName: "location.circle.fill")
//                                        .font(.title2)
//                                        .foregroundStyle(.blue)
//                                }
//                            }
//
//                            // Drain pins
//                            ForEach(nearbyDrains) { drain in
//                                Annotation(drain.title, coordinate: drain.coordinate) {
//                                    VStack(spacing: 4) {
//                                        Image(systemName: selectedDrain == drain ? "mappin.circle.fill" : "mappin.circle")
//                                            .font(.title2)
//                                            .foregroundStyle(selectedDrain == drain ? .red : .gray)
//                                            .onTapGesture {
//                                                selectedDrain = drain
//                                            }
//
//                                        if selectedDrain == drain {
//                                            Text(drain.title)
//                                                .font(.caption)
//                                                .padding(6)
//                                                .background(.white.opacity(0.95))
//                                                .cornerRadius(8)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        .frame(height: 260)
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
//
//                        // Helper text
//                        Text(selectedDrain == nil ? "Tap a pin to select the drain" : "Selected: \(selectedDrain!.title)")
//                            .font(.caption)
//                            .padding(8)
//                            .background(.thinMaterial)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                            .padding(10)
//                    }
//                    .onReceive(locationManager.$userLocation) { coord in
//                        guard let coord else { return }
//                        if !hasCentredOnUser {
//                            hasCentredOnUser = true
//                            position = .camera(MapCamera(centerCoordinate: coord, distance: 1200))
//                        }
//                    }
//
//                    // Optional: recenter button
//                    Button("Re-centre on my location") {
//                        if let coord = locationManager.userLocation {
//                            position = .camera(MapCamera(centerCoordinate: coord, distance: 1200))
//                        }
//                    }
//                }
//
//                // 3) Report content
//                Section("Report details") {
//                    TextField("Describe the clog (e.g., leaves, rubbish, strong smell)", text: $note, axis: .vertical)
//                        .lineLimit(3...6)
//
//                    if let err = errorMessage {
//                        Text(err)
//                            .foregroundStyle(.red)
//                    }
//                }
//
//                // 4) Submit
//                Section {
//                    Button {
//                        submit()
//                    } label: {
//                        HStack {
//                            Spacer()
//                            if isSubmitting {
//                                ProgressView()
//                            } else {
//                                Text("Submit report")
//                                    .fontWeight(.semibold)
//                            }
//                            Spacer()
//                        }
//                    }
//                    .disabled(!canSubmit || isSubmitting)
//                }
//            }
//            .navigationTitle("Report a drain")
//            .alert("Report submitted", isPresented: $showSuccess) {
//                Button("OK", role: .cancel) {}
//            } message: {
//                Text("Thanks for helping prevent flooding.")
//            }
//        }
//    }
//
//    private var canSubmit: Bool {
//        selectedDrain != nil && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//
//    private func submit() {
//        errorMessage = nil
//        guard let drain = selectedDrain else {
//            errorMessage = "Please select the correct drain on the map."
//            return
//        }
//
//        isSubmitting = true
//
//        // Build payload (you would send this to your backend / AI validation service)
//        let payload = DrainReportPayload(
//            drain: drain,
//            photo: capturedImage,
//            note: note,
//            reporterLocation: locationManager.userLocation,
//            createdAt: Date()
//        )
//
//        // TODO: replace with real API call
//        Task {
//            try? await Task.sleep(nanoseconds: 700_000_000)
//            await MainActor.run {
//                isSubmitting = false
//                showSuccess = true
//                print("Submitting:", payload) // remove in production
//            }
//        }
//    }
//}
