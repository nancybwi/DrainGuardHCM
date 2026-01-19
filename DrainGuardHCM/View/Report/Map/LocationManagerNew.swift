//
//  LocationManager.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 16/1/26.
//  Updated: 19/1/26 - Added lazy initialization and "While Using" permission
//

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isTracking = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Only update if moved 10+ meters
        authorizationStatus = manager.authorizationStatus
        print("📍 LocationManager initialized (not tracking yet)")
        print("📍 Current authorization: \(authorizationStatus.rawValue)")
    }
    
    // MARK: - Control Methods
    
    /// Start tracking location - call when map view appears
    @MainActor
    func startTracking() {
        guard !isTracking else {
            print("📍 Already tracking")
            return
        }
        
        print("📍 Starting location tracking...")
        print("📍 Authorization status: \(manager.authorizationStatus.rawValue)")
        
        // Request "When In Use" permission (not "Always")
        switch manager.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting 'When In Use' authorization...")
            manager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            print("⚠️ Location access denied or restricted")
            locationError = "Location access denied. Please enable in Settings → DrainGuard → Location"
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location authorized, starting updates")
            
        @unknown default:
            print("⚠️ Unknown authorization status")
        }
        
        manager.startUpdatingLocation()
        isTracking = true
    }
    
    /// Stop tracking location - call when map view disappears
    @MainActor
    func stopTracking() {
        guard isTracking else { return }
        
        print("📍 Stopping location tracking")
        manager.stopUpdatingLocation()
        isTracking = false
    }
    
    /// Request single location (for one-time use like submitting a report)
    @MainActor
    func requestSingleLocation() {
        print("📍 Requesting single location...")
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access denied. Enable in Settings."
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
        
        manager.requestLocation()
    }
    
    // MARK: - Convenience Properties
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var hasLocation: Bool {
        userLocation != nil
    }
    
    var currentAccuracyMeters: Double? {
        manager.location?.horizontalAccuracy
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter old/inaccurate locations
        guard location.timestamp.timeIntervalSinceNow > -5,
              location.horizontalAccuracy > 0,
              location.horizontalAccuracy < 100 else {
            print("📍 Skipping location: too old or inaccurate")
            return
        }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude) ±\(Int(location.horizontalAccuracy))m")
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied. Enable in Settings → DrainGuard → Location → While Using App"
                    print("⚠️ Location error: Access denied")
                case .locationUnknown:
                    self.locationError = "Unable to determine location. Try again."
                    print("⚠️ Location error: Location unknown")
                case .network:
                    self.locationError = "Network error. Check your connection."
                    print("⚠️ Location error: Network issue")
                default:
                    self.locationError = error.localizedDescription
                    print("⚠️ Location error: \(error.localizedDescription)")
                }
            } else {
                self.locationError = error.localizedDescription
                print("⚠️ Location error: \(error.localizedDescription)")
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("📍 Authorization changed to: \(manager.authorizationStatus.rawValue)")
            
            switch manager.authorizationStatus {
            case .notDetermined:
                print("📍 Waiting for user to grant permission...")
                
            case .authorizedWhenInUse:
                print("📍 ✅ Authorized 'When In Use'")
                // Auto-start if we were trying to track
                if self.isTracking {
                    manager.startUpdatingLocation()
                }
                
            case .authorizedAlways:
                print("📍 ✅ Authorized 'Always' (more than needed)")
                if self.isTracking {
                    manager.startUpdatingLocation()
                }
                
            case .denied:
                print("⚠️ ❌ User denied location access")
                self.locationError = "Location denied. Enable in Settings → DrainGuard → Location"
                self.isTracking = false
                
            case .restricted:
                print("⚠️ ❌ Location restricted (parental controls?)")
                self.locationError = "Location access is restricted"
                self.isTracking = false
                
            @unknown default:
                print("⚠️ Unknown authorization status")
            }
        }
    }
}
