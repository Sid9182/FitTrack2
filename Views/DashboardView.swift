import SwiftUI
import Charts
import MapKit

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var showTracking = false

    var body: some View {
        ZStack {
            Color(hex: "121212").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingSection
                    metricsSection
                    weeklyChart
                    recentActivities
                }
                .padding()
            }

            trackingButton
        }
        .navigationTitle("FitTrack")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refreshActivities()
        }
        .fullScreenCover(isPresented: $showTracking) {
            TrackingView(isPresented: $showTracking)
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, Athlete")
                .font(.largeTitle.bold())
            Text(Date().formattedGreeting())
                .font(.subheadline)
                .foregroundColor(Color(hex: "B3B3B3"))
        }
    }

    private var metricsSection: some View {
        HStack(spacing: 16) {
            metricCard(title: "Weekly", value: "\(viewModel.weeklyTotal.asDistanceString()) km")
            metricCard(title: "Best Pace", value: viewModel.bestPace > 0 ? viewModel.bestPace.asPaceString() : "--:--")
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "B3B3B3"))
            Text(value)
                .font(.title2.bold())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly distance")
                .font(.headline)
            Chart(viewModel.weeklyData) { dataPoint in
                BarMark(
                    x: .value("Day", dataPoint.day),
                    y: .value("Distance", dataPoint.distance)
                )
                .foregroundStyle(dataPoint.day == DateFormatter.shortWeekday.string(from: Date()) ? Color(hex: "1DB954") : Color.gray)
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
            .padding(12)
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
        }
    }

    private var recentActivities: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent activities")
                .font(.headline)
            if viewModel.activities.isEmpty {
                Text("No activities yet. Start a new session to track your first workout.")
                    .foregroundColor(Color(hex: "B3B3B3"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(12)
            } else {
                ForEach(viewModel.activities, id: \.objectID) { activity in
                    NavigationLink(destination: ActivityDetailView(activity: activity)) {
                        activityRow(activity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func activityRow(_ activity: Activity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ActivityType(rawValue: activity.wrappedType)?.iconName ?? "figure.run")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(hex: "1DB954"))
                .foregroundColor(.black)
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text(ActivityType(rawValue: activity.wrappedType)?.displayName ?? "Run")
                    .font(.headline)
                Text(activity.wrappedDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "B3B3B3"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.duration.asDurationString())
                    .font(.headline)
                Text("\(activity.totalDistance.asDistanceString()) km")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "B3B3B3"))
            }
        }
        .padding()
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
    }

    private var trackingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showTracking = true }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "1DB954"))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding()
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: previewViewModel)
            .background(Color(hex: "121212"))
    }

    static var previewViewModel: DashboardViewModel {
        let model = DashboardViewModel()
        model.activities = PreviewData.sampleActivities
        model.weeklyData = PreviewData.sampleWeeklyData
        model.bestPace = 300
        model.weeklyTotal = 16.2
        return model
    }
}
