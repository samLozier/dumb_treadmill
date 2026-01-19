# Review Findings (Initial)

## Summary of intent
- watchOS SwiftUI app to manually start/pause/finish treadmill sessions.
- Pace-based distance/calorie simulation with heart-rate display.
- Save workouts and samples to HealthKit.

## Findings / Checklist
1. [x] Two `WorkoutManager` instances are created (app-level environment vs `ContentView`), so state is not shared as intended. (`dumb_treadmill Watch App/dumb_treadmillApp.swift`, `dumb_treadmill Watch App/ContentView.swift`)
2. [x] `DuringWorkoutView` calls `resumeWorkout()` on appear even when already active, which can spawn a second timer/query; `TimerManager.resume()` does not cancel existing timer. (`dumb_treadmill Watch App/DuringWorkoutView.swift`, `dumb_treadmill Watch App/TimerManager.swift`)
3. [x] HealthKit authorization does not include `distanceWalkingRunning` or `activeEnergyBurned`, but those are written later. (`dumb_treadmill Watch App/HealthKitManager.swift`, `dumb_treadmill Watch App/WorkoutManager.swift`)
4. [x] Distance units are inconsistent (UI uses miles; HealthKit workout distance saved as meters while samples are saved as miles). Need to store absolute distance in HealthKit units (meters) while letting UI default to miles and support a user preference toggle. (`dumb_treadmill Watch App/TimerManager.swift`, `dumb_treadmill Watch App/TimeInterval+Formatting.swift`, `dumb_treadmill Watch App/HealthKitManager.swift`)
5. [x] Saving view likely disappears before showing its transient confirmation because workout state flips back to idle immediately after save completion. (`dumb_treadmill Watch App/WorkoutManager.swift`, `dumb_treadmill Watch App/SavingWorkoutView.swift`)

## User preferences clarified
- Store absolute distance in HealthKit-preferred units (meters).
- UI should default to miles, with a user preference for miles/kilometers (or meters) for display.
- Saving workout view should be transient and clear to next screen after save is confirmed.

## Project Cleanup & Standardization Checklist (Prioritized)
1. [x] Get testing working end‑to‑end (simulator runtime + reliable `xcodebuild test` run).
2. [x] Centralize workout save state and transitions in `WorkoutManager` to avoid UI‑driven state resets or double transitions; `SavingWorkoutView` should be read‑only. (`dumb_treadmill Watch App/WorkoutManager.swift`, `dumb_treadmill Watch App/SavingWorkoutView.swift`)
3. [x] Clarify HealthKit save contract: either remove unused `distance`/`totalEnergyBurned` parameters in `endWorkout` or use them consistently (no mixed streaming + total samples). (`dumb_treadmill Watch App/HealthKitManager.swift`)
4. [x] Use real elapsed deltas for HealthKit sample timestamps rather than `now - 1` to avoid drift and mismatched totals. (`dumb_treadmill Watch App/WorkoutManager.swift`, `dumb_treadmill Watch App/TimerManager.swift`)
5. [x] Add a shared “metrics stack” view so `DuringWorkoutView` and `PausedView` stay in sync for layout/labels/formatting. (`dumb_treadmill Watch App/DuringWorkoutView.swift`, `dumb_treadmill Watch App/PausedView.swift`)
6. [x] Replace `print` statements with `os.Logger` and add a basic logging policy for device builds. (`dumb_treadmill Watch App/HealthKitManager.swift`, `dumb_treadmill Watch App/HeartRateManager.swift`, `dumb_treadmill Watch App/WorkoutManager.swift`)
7. [x] Consolidate pacing constants (min/max, step, debounce) in a shared config instead of hard‑coding in views/managers. (`dumb_treadmill Watch App/PaceControlView.swift`, `dumb_treadmill Watch App/TimerManager.swift`)
8. [ ] Replace brittle UI test string matching with accessibility identifiers for key controls and screens. (`dumb_treadmill Watch AppUITests/dumb_treadmill_Watch_AppUITests.swift`)
9. [ ] Remove placeholder unit tests or make them assert real behavior. (`dumb_treadmill Watch AppTests/dumb_treadmill_Watch_AppTests.swift`)
10. [ ] Require explicit simulator selection in `scripts/run-tests.sh` to avoid flakiness with “Any watchOS Simulator Device.” (`scripts/run-tests.sh`)
11. [ ] Add a short README with build/run/test instructions and simulator/runtime prerequisites. (new `README.md`)
