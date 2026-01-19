import SwiftUI

struct WorkoutMetricsView: View {
    let heartRate: Double
    let elapsedTime: TimeInterval
    let distance: Double
    let paceMph: Double?
    let distanceUnit: DistanceUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("❤️ \(heartRate, specifier: "%.0f") bpm")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("⏳ \(elapsedTime.formatted())")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("👣 \(distance.formattedDistance(unit: distanceUnit))")
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let paceMph {
                Text("🏃 \(paceMph, specifier: "%.1f") mph")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}
