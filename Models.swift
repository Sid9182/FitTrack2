import Foundation
import CoreLocation
import SwiftUI

@objc(Activity)
public class Activity: NSManagedObject {
}

@objc(LocationPoint)
public class LocationPoint: NSManagedObject {
}

public struct ActiveSession {
    let id: UUID
    let date: Date
    let type: String
    let duration: Double
    let totalDistance: Double
}

public struct DayDistance: Identifiable {
    public let id = UUID()
    public let day: String
    public let distance: Double
}

public struct ElevationPoint: Identifiable {
    public let id = UUID()
    public let distance: Double
    public let altitude: Double
}

public struct Split: Identifiable {
    public let id = UUID()
    public let km: Int
    public let pace: Double
}

public enum ActivityType: String, CaseIterable, Identifiable {
    case run
    case walk
    case cycle

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .run: return "Run"
        case .walk: return "Walk"
        case .cycle: return "Cycle"
        }
    }

    public var iconName: String {
        switch self {
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .cycle: return "bicycle"
        }
    }
}

extension Activity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Activity> {
        NSFetchRequest<Activity>(entityName: "Activity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var duration: Double
    @NSManaged public var totalDistance: Double
    @NSManaged public var points: NSOrderedSet?

    public var wrappedType: String { type ?? ActivityType.run.rawValue }
    public var wrappedDate: Date { date ?? Date() }
    public var orderedPoints: [LocationPoint] {
        (points?.array as? [LocationPoint]) ?? []
    }
}

extension LocationPoint {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationPoint> {
        NSFetchRequest<LocationPoint>(entityName: "LocationPoint")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var altitude: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var speed: Double
    @NSManaged public var activity: Activity?

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CLLocation {
    var asLocationPoint: (latitude: Double, longitude: Double, altitude: Double, timestamp: Date, speed: Double) {
        (coordinate.latitude, coordinate.longitude, altitude, timestamp, speed)
    }
}

extension Date {
    func formattedGreeting() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }
}

extension Double {
    func asDistanceString() -> String {
        String(format: "%.2f", self / 1000)
    }

    func asDurationString() -> String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func asPaceString() -> String {
        let paceSeconds = Int(self)
        let minutes = paceSeconds / 60
        let seconds = paceSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum PreviewData {
    static let sampleActivity: Activity = {
        let context = CoreDataManager.shared.mainContext
        let activity = Activity(context: context)
        activity.id = UUID()
        activity.date = Date()
        activity.type = ActivityType.run.rawValue
        activity.duration = 2850
        activity.totalDistance = 8200

        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7790, longitude: -122.4150),
            CLLocationCoordinate2D(latitude: 37.7825, longitude: -122.4100),
            CLLocationCoordinate2D(latitude: 37.7850, longitude: -122.4050)
        ]

        let points = coordinates.enumerated().map { index, coordinate -> LocationPoint in
            let point = LocationPoint(context: context)
            point.latitude = coordinate.latitude
            point.longitude = coordinate.longitude
            point.altitude = Double(20 + index * 3)
            point.timestamp = Date().addingTimeInterval(Double(index) * 180)
            point.speed = 3.5
            point.activity = activity
            return point
        }

        activity.points = NSOrderedSet(array: points)
        return activity
    }()

    static let sampleActivities: [Activity] = [sampleActivity]
    static let sampleWeeklyData: [DayDistance] = [
        DayDistance(day: "Mon", distance: 2500),
        DayDistance(day: "Tue", distance: 3800),
        DayDistance(day: "Wed", distance: 5200),
        DayDistance(day: "Thu", distance: 1900),
        DayDistance(day: "Fri", distance: 6000),
        DayDistance(day: "Sat", distance: 7400),
        DayDistance(day: "Sun", distance: 8200)
    ]
}
