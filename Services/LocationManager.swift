import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var locationPoints: [CLLocation] = []

    private let manager = CLLocationManager()
    private var isTracking = false

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() {
        guard CLLocationManager.authorizationStatus() != .denied else { return }
        isTracking = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        let newLocations = locations.filter { $0.horizontalAccuracy >= 0 }
        if let latest = newLocations.last {
            DispatchQueue.main.async {
                self.currentLocation = latest
                if self.isTracking {
                    self.locationPoints.append(latest)
                }
            }
        }
    }
}
