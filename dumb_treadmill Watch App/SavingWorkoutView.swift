import SwiftUI
import HealthKit

struct SavingWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue
    @AppStorage("lastEffort") private var lastEffort: Int = 0
    @State private var effort: Int = 5
    @State private var isSavingEffort = false
    @State private var showEffortPrompt = false

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        let distance = workoutManager.finalDistance
        let totalEnergyBurned = workoutManager.finalEnergyBurned
        let startDate = workoutManager.finalStartDate
        let endDate = workoutManager.finalEndDate

        return ScrollView {
            VStack {
                switch workoutManager.saveState {
                case .saving:
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .accessibilityIdentifier("savingProgress")

                    Text("Saving Workout...")
                        .font(.title2)
                        .padding()
                        .accessibilityIdentifier("savingTitle")

                    Text("Please wait while we save your workout.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                case .completed:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Workout Saved")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityIdentifier("saveCompletedTitle")

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
                        VStack(spacing: 8) {
                            Button("Add Effort") {
                                showEffortPrompt = true
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("addEffortButton")

                            Button("Skip") {
                                finishSaving()
                            }
                            .accessibilityIdentifier("skipEffortButton")
                        }
                        .padding()
                    } else {
                        Button("Done") {
                            finishSaving()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                        .accessibilityIdentifier("savingDoneButton")
                    }
                case .failed:
                    VStack(spacing: 12) {
                        Text("Save Failed")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityIdentifier("saveFailedTitle")

                        Text("We couldn’t save this workout. You can try again from the paused screen.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Button("Back to Paused") {
                            workoutManager.handleSaveFailure()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("saveFailureBackButton")
                    }
                    .padding()
                case .idle:
                    EmptyView()
                }
            }
            .padding()
        }
        .onAppear {
            effort = max(1, min(lastEffort == 0 ? 5 : lastEffort, 10))
            showEffortPrompt = false
        }
        .onChange(of: workoutManager.saveState) { _, newValue in
            guard newValue == .completed, workoutManager.canSaveWorkoutEffort else {
                return
            }
            showEffortPrompt = true
        }
        .sheet(isPresented: $showEffortPrompt) {
            EffortPromptView(
                effort: $effort,
                isSaving: isSavingEffort,
                onSave: {
                    isSavingEffort = true
                    workoutManager.saveWorkoutEffort(score: Double(effort)) { success in
                        if success {
                            lastEffort = effort
                        }
                        isSavingEffort = false
                        finishSaving()
                    }
                },
                onSkip: {
                    finishSaving()
                }
            )
        }
    }

    private func finishSaving() {
        workoutManager.completeSaving()
    }
}

private struct EffortPromptView: View {
    @Binding var effort: Int
    let isSaving: Bool
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("💪 Effort")
                .font(.subheadline)
            Text("How hard did it feel?")
                .font(.caption2)
                .foregroundColor(.secondary)

            Picker("Effort", selection: $effort) {
                ForEach(1...10, id: \.self) { value in
                    Text("\(value)")
                        .tag(value)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 90)
            .clipped()

            if isSaving {
                ProgressView("Saving effort...")
            } else {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)

                Button("Skip") {
                    onSkip()
                }
            }
        }
        .padding()
    }
}
