import SwiftUI
import HealthKit

struct SavingWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue
    @AppStorage("lastEffort") private var lastEffort: Int = 0
    @State private var effort: Int = 5
    @State private var isSavingEffort = false

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        let distance = workoutManager.finalDistance
        let totalEnergyBurned = workoutManager.finalEnergyBurned
        let startDate = workoutManager.finalStartDate
        let endDate = startDate.addingTimeInterval(workoutManager.elapsedTime)

        return ScrollView {
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()

                Text("Saving Workout...")
                    .font(.title2)
                    .padding()

                Text("Please wait while we save your workout.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)

                if workoutManager.saveCompleted {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workout Saved")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("👣 \(distance.formattedDistance(unit: distanceUnit))")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("🔥 \(totalEnergyBurned.formattedCalories())")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("▶️ \(startDate.formatted(date: .numeric, time: .shortened))")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("⏹️ \(endDate.formatted(date: .numeric, time: .shortened))")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding()
                    .foregroundColor(.gray)

                    if workoutManager.canSaveWorkoutEffort {
                        VStack(spacing: 12) {
                            Text("💪 Effort")
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Stepper("Effort \(effort)", value: $effort, in: 1...10)

                            if isSavingEffort {
                                ProgressView("Saving effort...")
                            } else {
                                Button("Save Effort") {
                                    isSavingEffort = true
                                    workoutManager.saveWorkoutEffort(score: Double(effort)) { success in
                                        if success {
                                            lastEffort = effort
                                        }
                                        isSavingEffort = false
                                        finishSaving()
                                    }
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Skip") {
                                    finishSaving()
                                }
                            }
                        }
                        .padding()
                    } else {
                        Button("Done") {
                            finishSaving()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .padding()
        }
        .onAppear {
            workoutManager.saveCompleted = false
            effort = max(1, min(lastEffort == 0 ? 5 : lastEffort, 10))
        }
    }

    private func finishSaving() {
        workoutManager.completeSaving()
    }
}
