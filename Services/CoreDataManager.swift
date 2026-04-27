import Foundation
import CoreData
import CoreLocation
import Combine

extension Notification.Name {
    static let activitySaved = Notification.Name("activitySaved")
}

final class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer
    var mainContext: NSManagedObjectContext { container.viewContext }

    private init() {
        let model = CoreDataManager.makeModel()
        container = NSPersistentContainer(name: "FitTrack", managedObjectModel: model)
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let activity = NSEntityDescription()
        activity.name = "Activity"
        activity.managedObjectClassName = NSStringFromClass(Activity.self)

        let activityId = NSAttributeDescription()
        activityId.name = "id"
        activityId.attributeType = .UUIDAttributeType
        activityId.isOptional = false

        let activityDate = NSAttributeDescription()
        activityDate.name = "date"
        activityDate.attributeType = .dateAttributeType
        activityDate.isOptional = false

        let activityType = NSAttributeDescription()
        activityType.name = "type"
        activityType.attributeType = .stringAttributeType
        activityType.isOptional = false

        let duration = NSAttributeDescription()
        duration.name = "duration"
        duration.attributeType = .doubleAttributeType
        duration.isOptional = false

        let totalDistance = NSAttributeDescription()
        totalDistance.name = "totalDistance"
        totalDistance.attributeType = .doubleAttributeType
        totalDistance.isOptional = false

        let point = NSEntityDescription()
        point.name = "LocationPoint"
        point.managedObjectClassName = NSStringFromClass(LocationPoint.self)

        let latitude = NSAttributeDescription()
        latitude.name = "latitude"
        latitude.attributeType = .doubleAttributeType
        latitude.isOptional = false

        let longitude = NSAttributeDescription()
        longitude.name = "longitude"
        longitude.attributeType = .doubleAttributeType
        longitude.isOptional = false

        let altitude = NSAttributeDescription()
        altitude.name = "altitude"
        altitude.attributeType = .doubleAttributeType
        altitude.isOptional = false

        let timestamp = NSAttributeDescription()
        timestamp.name = "timestamp"
        timestamp.attributeType = .dateAttributeType
        timestamp.isOptional = false

        let speed = NSAttributeDescription()
        speed.name = "speed"
        speed.attributeType = .doubleAttributeType
        speed.isOptional = false

        let activityToPoints = NSRelationshipDescription()
        activityToPoints.name = "points"
        activityToPoints.destinationEntity = point
        activityToPoints.deleteRule = .cascadeDeleteRule
        activityToPoints.isOrdered = true
        activityToPoints.maxCount = 0
        activityToPoints.minCount = 0

        let pointToActivity = NSRelationshipDescription()
        pointToActivity.name = "activity"
        pointToActivity.destinationEntity = activity
        pointToActivity.deleteRule = .nullifyDeleteRule
        pointToActivity.maxCount = 1
        pointToActivity.minCount = 0
        pointToActivity.isOrdered = false

        activityToPoints.inverseRelationship = pointToActivity
        pointToActivity.inverseRelationship = activityToPoints

        activity.properties = [activityId, activityDate, activityType, duration, totalDistance, activityToPoints]
        point.properties = [latitude, longitude, altitude, timestamp, speed, pointToActivity]

        model.entities = [activity, point]
        return model
    }

    func saveActivity(session: ActiveSession, points: [CLLocation]) {
        let context = container.newBackgroundContext()
        context.perform {
            let activity = Activity(context: context)
            activity.id = session.id
            activity.date = session.date
            activity.type = session.type
            activity.duration = session.duration
            activity.totalDistance = session.totalDistance

            let orderedPoints = points.map { location -> LocationPoint in
                let point = LocationPoint(context: context)
                point.latitude = location.coordinate.latitude
                point.longitude = location.coordinate.longitude
                point.altitude = location.altitude
                point.timestamp = location.timestamp
                point.speed = location.speed
                point.activity = activity
                return point
            }

            activity.points = NSOrderedSet(array: orderedPoints)

            do {
                try context.save()
                NotificationCenter.default.post(name: .activitySaved, object: nil)
            } catch {
                print("Failed to save activity: \(error)")
            }
        }
    }

    func fetchActivities() async -> [Activity] {
        let request: NSFetchRequest<Activity> = Activity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.date, ascending: false)]

        return await withCheckedContinuation { continuation in
            container.viewContext.perform {
                do {
                    let results = try self.container.viewContext.fetch(request)
                    continuation.resume(returning: results)
                } catch {
                    print("Failed to fetch activities: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
