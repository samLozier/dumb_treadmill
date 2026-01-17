import SwiftUI

struct PaceControlView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var pendingPace: Double = 3.0
    @State private var updateWorkItem: DispatchWorkItem?
    @FocusState private var isFocused: Bool

    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)
            Text("\(pendingPace, specifier: "%.1f") mph")
                .font(.title2)
                .focusable(true)
                .focused($isFocused)
                .digitalCrownRotation(
                    $pendingPace,
                    from: 0.5,
                    through: 12.0,
                    by: 0.1,
                    sensitivity: .medium,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
        }
        .onAppear {
            pendingPace = workoutManager.currentPaceMph
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onDisappear {
            isFocused = false
        }
        .onChange(of: pendingPace) { _, newValue in
            schedulePaceUpdate(newValue)
        }
    }

    private func schedulePaceUpdate(_ pace: Double) {
        updateWorkItem?.cancel()
        let item = DispatchWorkItem {
            workoutManager.updatePace(paceMph: pace)
        }
        updateWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: item)
    }
}
