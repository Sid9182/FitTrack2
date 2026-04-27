import SwiftUI
import MapKit

struct TrackingView: View {
    @StateObject private var viewModel = TrackingViewModel()
    @Binding var isPresented: Bool
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )
    @State private var pulse = false

    private struct AnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "121212").ignoresSafeArea()
            mapView
            overlaySheet
            topBar
        }
        .onChange(of: viewModel.routePoints) { points in
            if let location = points.last {
                region.center = location.coordinate
            }
        }
        .onAppear {
            viewModel.startTracking()
        }
    }

    private var mapView: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: [.all],
            showsUserLocation: true,
            annotationItems: lastAnnotation.map { [$0] } ?? []
        ) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Circle()
                    .fill(Color(hex: "1DB954"))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .scaleEffect(pulse ? 1.4 : 1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
            }
        }
        .ignoresSafeArea()
    }

    private var lastAnnotation: AnnotationItem? {
        guard let location = viewModel.routePoints.last else { return nil }
        return AnnotationItem(coordinate: location.coordinate)
    }

    private var overlaySheet: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                statsRow
                paceStrip
                stopButton
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .padding()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(title: "Distance", value: "\(viewModel.distance.asDistanceString()) km")
            statCard(title: "Time", value: viewModel.elapsedTime.asDurationString())
            statCard(title: "Pace", value: viewModel.currentPace > 0 ? viewModel.currentPace.asPaceString() : "--:--")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "B3B3B3"))
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "2A2A2A"), lineWidth: 0.5))
    }

    private var paceStrip: some View {
        HStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(colorForSegment(index))
                    .frame(height: 8)
                    .cornerRadius(4)
            }
        }
    }

    private func colorForSegment(_ index: Int) -> Color {
        guard !viewModel.recentPaces.isEmpty else { return Color(hex: "2A2A2A") }
        let value = viewModel.recentPaces[index % viewModel.recentPaces.count]
        if value <= 300 { return Color(hex: "1DB954") }
        if value <= 360 { return Color.yellow }
        return Color.red
    }

    private var stopButton: some View {
        Button(action: stopTracking) {
            Text("Stop")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(24)
        }
    }

    private var topBar: some View {
        Button(action: dismiss) {
            Label("Cancel", systemImage: "xmark")
                .font(.headline)
                .foregroundColor(.white)
                .padding(14)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(.leading, 20)
                .padding(.top, 40)
        }
    }

    private func stopTracking() {
        viewModel.stopTracking()
        isPresented = false
    }

    private func dismiss() {
        viewModel.cancelTracking()
        isPresented = false
    }
}

struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView(isPresented: .constant(true))
            .background(Color(hex: "121212"))
    }
}
