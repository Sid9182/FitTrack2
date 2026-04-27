import SwiftUI
import Charts
import MapKit

struct ActivityDetailView: View {
    @StateObject private var viewModel: ActivityDetailViewModel

    private struct SegmentOverlay: Identifiable {
        let id = UUID()
        let coordinates: [CLLocationCoordinate2D]
        let color: Color
    }

    init(activity: Activity) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mapSection
                headerSection
                statsChips
                legendStrip
                elevationChart
                splitsList
            }
            .padding()
            .background(Color(hex: "121212").ignoresSafeArea())
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mapSection: some View {
        let overlays = viewModel.paceSegments.map { SegmentOverlay(coordinates: $0.coordinates, color: $0.color) }

        return Map(
            coordinateRegion: .constant(viewModel.routeRegion),
            interactionModes: [.all],
            overlayItems: overlays
        ) { overlay in
            MapPolyline(coordinates: overlay.coordinates)
                .stroke(overlay.color, lineWidth: 6)
        }
        .frame(height: 260)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Morning Run")
                    .font(.title2.bold())
                Text(viewModel.activity.wrappedDate, style: .date)
                    .foregroundColor(Color(hex: "B3B3B3"))
            }
            Spacer()
            Button(action: shareActivity) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(Color(hex: "1DB954"))
                    .padding(12)
                    .background(Color(hex: "1A1A1A"))
                    .cornerRadius(16)
            }
        }
    }

    private var statsChips: some View {
        HStack(spacing: 12) {
            chip(title: "Distance", value: "\(viewModel.activity.totalDistance.asDistanceString()) km")
            chip(title: "Duration", value: viewModel.activity.duration.asDurationString())
            chip(title: "Best km", value: viewModel.bestKmPace.asPaceString())
        }
    }

    private func chip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "B3B3B3"))
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
    }

    private var legendStrip: some View {
        HStack(alignment: .center) {
            HStack(spacing: 4) {
                Color.red.frame(width: 24, height: 8).cornerRadius(4)
                Color.orange.frame(width: 24, height: 8).cornerRadius(4)
                Color(hex: "1DB954").frame(width: 24, height: 8).cornerRadius(4)
            }
            Text("Slow")
                .foregroundColor(Color(hex: "B3B3B3"))
                .font(.caption)
            Spacer()
            Text("Fast")
                .foregroundColor(Color(hex: "B3B3B3"))
                .font(.caption)
        }
    }

    private var elevationChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elevation profile")
                .font(.headline)
            Chart(viewModel.elevationData) { point in
                AreaMark(
                    x: .value("Distance", point.distance),
                    y: .value("Altitude", point.altitude)
                )
                .foregroundStyle(LinearGradient(
                    colors: [Color(hex: "1DB954"), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            .frame(height: 180)
            .chartYAxis(.hidden)
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
        }
    }

    private var splitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Km splits")
                .font(.headline)
            ForEach(viewModel.splits) { split in
                HStack {
                    Text("Km \(split.km)")
                        .font(.subheadline)
                    ProgressView(value: min(split.pace / 420, 1))
                        .tint(Color(hex: "1DB954"))
                        .frame(maxWidth: .infinity)
                    Text(split.pace.asPaceString())
                        .font(.footnote)
                        .foregroundColor(Color(hex: "B3B3B3"))
                }
                .padding()
                .background(Color(hex: "1A1A1A"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
            }
        }
    }

    private func shareActivity() {
        // Placeholder for future share integration.
    }
}

struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityDetailView(activity: PreviewData.sampleActivity)
            .background(Color(hex: "121212"))
    }
}
