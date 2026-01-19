import SwiftUI

struct PreStartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue
    @AppStorage("userWeightLbs") private var userWeightLbs: Double = 185.0

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

                NavigationLink {
                    WeightPickerView()
                        .environmentObject(workoutManager)
                } label: {
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(Int(userWeightLbs)) lb")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                if workoutManager.healthKitAvailable {
                    Text("❤️ \(workoutManager.heartRate, specifier: "%.0f") bpm")
                } else {
                    Text("Heart rate not available")
                        .foregroundColor(.red)
                }
            }

            Section {
                Button("Start") {
                    workoutManager.startWorkout(pace: workoutManager.currentPaceMph)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("startWorkoutButton")
            }
        }
        .listStyle(.carousel)
        .onAppear {
            workoutManager.userWeightLbs = userWeightLbs
        }
        .onChange(of: userWeightLbs) { _, newValue in
            workoutManager.userWeightLbs = newValue
        }
    }
}
