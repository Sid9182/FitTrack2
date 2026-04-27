import SwiftUI

@main
struct FitTrackApp: App {
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DashboardView(viewModel: dashboardViewModel)
            }
            .preferredColorScheme(.dark)
            .environment(
                \.managedObjectContext,
                CoreDataManager.shared.mainContext
            )
        }
    }
}
