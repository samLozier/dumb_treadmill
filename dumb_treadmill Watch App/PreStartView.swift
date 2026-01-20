import SwiftUI

struct PreStartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    PaceControlView(title: "Speed")
                        .environmentObject(workoutManager)
                } label: {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text("\(workoutManager.currentPaceMph, specifier: "%.1f") mph")
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("startSpeedLink")
            }

            Section {
                NavigationLink {
                    DistanceUnitPickerView()
                } label: {
                    HStack {
                        Text("Units")
                        Spacer()
                        Text(distanceUnit.shortLabel)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("unitsLink")

            }

            Section {
                if workoutManager.healthKitAvailable {
                    Text("❤️ \(workoutManager.heartRate, specifier: "%.0f") bpm")
                } else {
                    Text("Heart rate not available")
                        .foregroundColor(.red)
                }
            }

            if workoutManager.healthKitAvailable && !workoutManager.distanceWriteAuthorized {
                Section {
                    Text("Distance permission is off. Distance won’t be saved.")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }

            Section {
                Button("Start") {
                    workoutManager.startWorkout(pace: workoutManager.currentPaceMph)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("startWorkoutButton")
                .disabled(workoutManager.healthKitAvailable && !workoutManager.distanceWriteAuthorized)
            }
        }
        .listStyle(.carousel)
    }
}
