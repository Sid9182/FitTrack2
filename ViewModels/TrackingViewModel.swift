import Foundation
import Combine
import CoreLocation

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var isTracking = false
    @Published var elapsedTime: Double = 0
    @Published var distance: Double = 0
    @Published var currentPace: Double = 0
    @Published var routePoints: [CLLocation] = []
    @Published var recentPaces: [Double] = []

    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var sessionStart: Date?
    private var lastLocation: CLLocation?
    private var activityType = ActivityType.run

    init() {
        setupBindings()
    }

    private func setupBindings() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self, self.isTracking else { return }
                self.appendLocation(location)
            }
            .store(in: &cancellables)
    }

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        elapsedTime = 0
        distance = 0
        currentPace = 0
        routePoints = []
        recentPaces = []
        lastLocation = nil
        sessionStart = Date()
        locationManager.startTracking()
        startTimer()
    }

    func stopTracking() {
        guard isTracking, let start = sessionStart else { return }
        isTracking = false
        locationManager.stopTracking()
        stopTimer()

        let session = ActiveSession(
            id: UUID(),
            date: start,
            type: activityType.rawValue,
            duration: elapsedTime,
            totalDistance: distance
        )

        CoreDataManager.shared.saveActivity(session: session, points: routePoints)
    }

    func cancelTracking() {
        isTracking = false
        locationManager.stopTracking()
        stopTimer()
        elapsedTime = 0
        distance = 0
        currentPace = 0
        routePoints = []
        recentPaces = []
        lastLocation = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.isTracking else { return }
            self.elapsedTime += 1
            self.updatePaceFromRecentPoints()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func appendLocation(_ location: CLLocation) {
        if let last = lastLocation {
            let segmentDistance = location.distance(from: last)
            if segmentDistance > 0 {
                distance += segmentDistance
            }
        }

        routePoints.append(location)
        lastLocation = location
        updatePaceFromRecentPoints()
    }

    private func updatePaceFromRecentPoints() {
        let recent = routePoints.suffix(8)
        guard recent.count >= 2 else { return }

        var totalDistance: Double = 0
        var totalDuration: Double = 0

        for pair in zip(recent, recent.dropFirst()) {
            totalDistance += pair.1.distance(from: pair.0)
            totalDuration += pair.1.timestamp.timeIntervalSince(pair.0.timestamp)
        }

        if totalDistance > 0 {
            let paceSeconds = totalDuration / (totalDistance / 1000)
            currentPace = paceSeconds
            recentPaces.append(paceSeconds)
            if recentPaces.count > 6 {
                recentPaces.removeFirst()
            }
        }
    }

    func routeCoordinates() -> [CLLocationCoordinate2D] {
        routePoints.map { $0.coordinate }
    }
}
