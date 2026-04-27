import Foundation
import CoreLocation
import SwiftUI
import MapKit

@MainActor
final class ActivityDetailViewModel: ObservableObject {
    let activity: Activity
    let routeCoordinates: [CLLocationCoordinate2D]
    let averagePace: Double

    init(activity: Activity) {
        self.activity = activity
        let points = activity.orderedPoints.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        routeCoordinates = points.map { $0.coordinate }
        averagePace = activity.totalDistance > 0 ? activity.duration / (activity.totalDistance / 1000) : 0
    }

    var paceSegments: [(coordinates: [CLLocationCoordinate2D], color: Color)] {
        let points = activity.orderedPoints.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        guard points.count > 1 else { return [] }

        var segments: [(coordinates: [CLLocationCoordinate2D], pace: Double)] = []
        for pair in zip(points, points.dropFirst()) {
            let start = pair.0
            let end = pair.1
            let distance = end.coordinate.distance(from: start.coordinate)
            let time = end.timestamp?.timeIntervalSince(start.timestamp ?? Date()) ?? 0
            let pace = distance > 0 ? time / (distance / 1000) : averagePace
            segments.append((coordinates: [start.coordinate, end.coordinate], pace: pace))
        }

        var output: [(coordinates: [CLLocationCoordinate2D], color: Color)] = []
        var currentColor: Color?
        var currentSegment: [CLLocationCoordinate2D] = []

        func flushSegment() {
            if let color = currentColor, currentSegment.count > 1 {
                output.append((coordinates: currentSegment, color: color))
            }
            currentSegment = []
            currentColor = nil
        }

        for segment in segments {
            let color = color(for: segment.pace)
            if currentColor == nil {
                currentColor = color
                currentSegment = segment.coordinates
            } else if currentColor == color {
                currentSegment.append(contentsOf: segment.coordinates.dropFirst())
            } else {
                flushSegment()
                currentColor = color
                currentSegment = segment.coordinates
            }
        }
        flushSegment()
        return output
    }

    var elevationData: [ElevationPoint] {
        let points = activity.orderedPoints.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        var cumulativeDistance: Double = 0
        var output: [ElevationPoint] = []

        for (index, point) in points.enumerated() {
            if index > 0 {
                let previous = points[index - 1]
                cumulativeDistance += point.coordinate.distance(from: previous.coordinate)
            }
            output.append(ElevationPoint(distance: cumulativeDistance / 1000, altitude: point.altitude))
        }

        return output
    }

    var splits: [Split] {
        let points = activity.orderedPoints.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        guard points.count > 1 else { return [] }

        var splits: [Split] = []
        var currentSplitDistance: Double = 0
        var currentSplitTime: Double = 0
        let goalDistance = 1000.0
        var coveredDistance: Double = 0

        for pair in zip(points, points.dropFirst()) {
            let start = pair.0
            let end = pair.1
            let segmentDistance = end.coordinate.distance(from: start.coordinate)
            let segmentTime = end.timestamp?.timeIntervalSince(start.timestamp ?? Date()) ?? 0
            coveredDistance += segmentDistance
            currentSplitDistance += segmentDistance
            currentSplitTime += segmentTime

            while coveredDistance >= goalDistance {
                let pace = currentSplitDistance > 0 ? currentSplitTime / (currentSplitDistance / 1000) : 0
                let kmNumber = splits.count + 1
                splits.append(Split(km: kmNumber, pace: pace))
                currentSplitDistance = 0
                currentSplitTime = 0
                coveredDistance -= goalDistance
            }
        }

        if currentSplitDistance > 0 {
            let pace = currentSplitDistance > 0 ? currentSplitTime / (currentSplitDistance / 1000) : 0
            splits.append(Split(km: splits.count + 1, pace: pace))
        }

        return splits
    }

    private func color(for pace: Double) -> Color {
        if pace <= averagePace * 0.95 {
            return Color("FitGreen")
        } else if pace <= averagePace * 1.1 {
            return Color.orange
        } else {
            return Color.red
        }
    }

    var bestKmPace: Double {
        splits.map { $0.pace }.min() ?? averagePace
    }

    var routeRegion: MKCoordinateRegion {
        let coordinates = routeCoordinates
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (latitudes.max()! + latitudes.min()!) / 2,
            longitude: (longitudes.max()! + longitudes.min()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (latitudes.max()! - latitudes.min()!) * 1.5),
            longitudeDelta: max(0.01, (longitudes.max()! - longitudes.min()!) * 1.5)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

private extension CLLocationCoordinate2D {
    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        let selfLocation = CLLocation(latitude: latitude, longitude: longitude)
        let otherLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return selfLocation.distance(from: otherLocation)
    }
}
