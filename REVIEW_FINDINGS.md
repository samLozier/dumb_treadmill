# Review Findings (Initial)

## Summary of intent
- watchOS SwiftUI app to manually start/pause/finish treadmill sessions.
- Pace-based distance/calorie simulation with heart-rate display.
- Save workouts and samples to HealthKit.

## Findings / Checklist
1. [x] Two `WorkoutManager` instances are created (app-level environment vs `ContentView`), so state is not shared as intended. (`dumb_treadmill Watch App/dumb_treadmillApp.swift`, `dumb_treadmill Watch App/ContentView.swift`)
2. [ ] `DuringWorkoutView` calls `resumeWorkout()` on appear even when already active, which can spawn a second timer/query; `TimerManager.resume()` does not cancel existing timer. (`dumb_treadmill Watch App/DuringWorkoutView.swift`, `dumb_treadmill Watch App/TimerManager.swift`)
3. [ ] HealthKit authorization does not include `distanceWalkingRunning` or `activeEnergyBurned`, but those are written later. (`dumb_treadmill Watch App/HealthKitManager.swift`, `dumb_treadmill Watch App/WorkoutManager.swift`)
4. [ ] Distance units are inconsistent (UI uses miles; HealthKit workout distance saved as meters while samples are saved as miles). Need to store absolute distance in HealthKit units (meters) while letting UI default to miles and support a user preference toggle. (`dumb_treadmill Watch App/TimerManager.swift`, `dumb_treadmill Watch App/TimeInterval+Formatting.swift`, `dumb_treadmill Watch App/HealthKitManager.swift`)
5. [ ] Saving view likely disappears before showing its transient confirmation because workout state flips back to idle immediately after save completion. (`dumb_treadmill Watch App/WorkoutManager.swift`, `dumb_treadmill Watch App/SavingWorkoutView.swift`)

## User preferences clarified
- Store absolute distance in HealthKit-preferred units (meters).
- UI should default to miles, with a user preference for miles/kilometers (or meters) for display.
- Saving workout view should be transient and clear to next screen after save is confirmed.
