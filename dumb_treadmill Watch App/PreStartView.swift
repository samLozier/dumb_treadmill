import SwiftUI

struct PreStartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var pace: Double = 3.0
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue
    @AppStorage("userWeightLbs") private var userWeightLbs: Double = 185.0

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        VStack {
            Text("Pace: \(pace, specifier: "%.1f") mph")
            Slider(value: $pace, in: 0...10, step: 0.1)

            Picker("Distance Units", selection: $distanceUnitRaw) {
                ForEach(DistanceUnit.allCases, id: \.rawValue) { unit in
                    Text(unit.displayName).tag(unit.rawValue)
                }
            }
            .pickerStyle(.wheel)

            VStack(spacing: 6) {
                Text("Weight: \(Int(userWeightLbs)) lb")
                Stepper("Weight", value: $userWeightLbs, in: 80...350, step: 1)
                    .labelsHidden()
            }

            if workoutManager.healthKitAvailable {
                Text("Heart Rate: \(workoutManager.heartRate, specifier: "%.0f") bpm")
            } else {
                Text("Heart rate not available")
                    .foregroundColor(.red)
            }

            Button(action: {
                workoutManager.startWorkout(pace: pace)
            }) {
                Text("Start")
            }
        }
        .padding()
        .onAppear {
            workoutManager.userWeightLbs = userWeightLbs
        }
        .onChange(of: userWeightLbs) { _, newValue in
            workoutManager.userWeightLbs = newValue
        }
    }
}
