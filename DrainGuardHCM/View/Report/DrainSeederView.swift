//
//  DrainSeederView.swift
//  DrainGuardHCM
//
//  Created by Assistant on 19/1/26.
//

import SwiftUI

/// Admin view to seed drains collection
struct DrainSeederView: View {
    @State private var isSeeding = false
    @State private var isChecking = false
    @State private var isClearing = false
    @State private var message = ""
    @State private var drainsExist = false
    
    private let seeder = DrainSeeder()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🌱 Drain Collection Manager")
                    .font(.title)
                    .bold()
                
                Divider()
                
                // Status
                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 14))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Check if drains exist
                VStack(spacing: 12) {
                    Button {
                        checkDrains()
                    } label: {
                        HStack {
                            if isChecking {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isChecking ? "Checking..." : "Check if Drains Exist")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSeeding || isChecking || isClearing)
                    
                    if drainsExist {
                        Text("✅ Drains collection already exists")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Divider()
                
                // Seed drains
                Button {
                    seedDrains()
                } label: {
                    HStack {
                        if isSeeding {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSeeding ? "Seeding..." : "Seed Drains Collection (20 drains)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isSeeding || isChecking || isClearing)
                
                // Clear drains (danger zone)
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Danger Zone")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    Button {
                        clearDrains()
                    } label: {
                        HStack {
                            if isClearing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isClearing ? "Clearing..." : "Clear All Drains")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isSeeding || isChecking || isClearing)
                    
                    Text("This will delete all drains from Firestore!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("📋 Instructions")
                        .font(.headline)
                    
                    Text("""
                    1. Tap "Check if Drains Exist" to see if the collection is already populated
                    
                    2. Tap "Seed Drains Collection" to add 20 sample drains across Ho Chi Minh City districts
                    
                    3. Check Xcode console for detailed logs
                    
                    4. Verify in Firebase Console → Firestore → drains collection
                    
                    Note: You only need to do this once!
                    """)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            checkDrains()
        }
    }
    
    // MARK: - Actions
    
    private func checkDrains() {
        isChecking = true
        message = "Checking..."
        
        Task {
            do {
                let exists = try await seeder.checkDrainsExist()
                
                await MainActor.run {
                    drainsExist = exists
                    message = exists ? "✅ Drains collection exists" : "⚠️ Drains collection is empty"
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    message = "❌ Error checking: \(error.localizedDescription)"
                    isChecking = false
                }
            }
        }
    }
    
    private func seedDrains() {
        isSeeding = true
        message = "Seeding drains..."
        
        Task {
            do {
                try await seeder.seedDrains()
                
                await MainActor.run {
                    message = "✅ Successfully seeded drains collection! Check console for details."
                    drainsExist = true
                    isSeeding = false
                }
            } catch {
                await MainActor.run {
                    message = "❌ Seeding failed: \(error.localizedDescription)"
                    isSeeding = false
                }
            }
        }
    }
    
    private func clearDrains() {
        isClearing = true
        message = "Clearing drains..."
        
        Task {
            do {
                try await seeder.clearDrains()
                
                await MainActor.run {
                    message = "✅ Cleared drains collection"
                    drainsExist = false
                    isClearing = false
                }
            } catch {
                await MainActor.run {
                    message = "❌ Clear failed: \(error.localizedDescription)"
                    isClearing = false
                }
            }
        }
    }
}

#Preview {
    DrainSeederView()
}
