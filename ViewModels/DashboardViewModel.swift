import Foundation
import Combine
import CoreData

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var weeklyData: [DayDistance] = []
    @Published var bestPace: Double = 0
    @Published var weeklyTotal: Double = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeSaves()
        Task { await refreshActivities() }
    }

    private func observeSaves() {
        NotificationCenter.default.publisher(for: .activitySaved)
            .sink { [weak self] _ in
                Task { await self?.refreshActivities() }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func refreshActivities() async {
        activities = await CoreDataManager.shared.fetchActivities()
        computeWeeklySummary()
    }

    private func computeWeeklySummary() {
        let calendar = Calendar.current
        let today = Date()
        let lastSevenDays = (0..<7).map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        }.reversed()

        weeklyData = lastSevenDays.map { date in
            let dayName = DateFormatter.shortWeekday.string(from: date)
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            let dailyDistance = activities
                .filter { ($0.wrappedDate >= startOfDay) && ($0.wrappedDate < endOfDay) }
                .reduce(0) { $0 + $1.totalDistance }
            return DayDistance(day: dayName, distance: dailyDistance)
        }

        weeklyTotal = weeklyData.reduce(0) { $0 + $1.distance }

        let paceValues = activities.compactMap { activity -> Double? in
            guard activity.totalDistance > 0 else { return nil }
            return activity.duration / (activity.totalDistance / 1000)
        }

        bestPace = paceValues.min() ?? 0
    }
}

private extension DateFormatter {
    static let shortWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
}
