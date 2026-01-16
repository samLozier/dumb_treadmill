# Repository Guidelines

## Project Structure & Module Organization
This is a watchOS SwiftUI app. Key locations:
- `dumb_treadmill Watch App/` contains app source (views, managers, app entry).
- `dumb_treadmill Watch App/Assets.xcassets/` holds app icons, colors, and other assets.
- `dumb_treadmill Watch AppTests/` and `dumb_treadmill Watch AppUITests/` contain XCTest-based unit/UI tests.
- `dumb_treadmill Watch App.xctestplan` defines the test plan used by Xcode.
- `dumb_treadmill.xcodeproj/` is the Xcode project configuration.

## Build, Test, and Development Commands
Use Xcode for day-to-day development. Example CLI commands:
- `xcodebuild -scheme "dumb_treadmill Watch App" -destination "generic/platform=watchOS" build` builds the app.
- `xcodebuild -scheme "dumb_treadmill Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)" test` runs tests on a simulator (adjust device name as needed).
If you add new schemes or targets, keep names consistent with the main app.

## Coding Style & Naming Conventions
- Indentation: 4 spaces, no tabs.
- Swift naming: types use `UpperCamelCase`, functions/properties use `lowerCamelCase`.
- Prefer SwiftUI view structs per screen (e.g., `DuringWorkoutView.swift`).
- Keep managers focused (e.g., `WorkoutManager.swift`, `HealthKitManager.swift`).
No formatter or linter is configured; follow standard Swift and SwiftUI conventions.

## Testing Guidelines
- Framework: XCTest.
- Place unit tests in `dumb_treadmill Watch AppTests/` and UI tests in `dumb_treadmill Watch AppUITests/`.
- Test classes should end in `Tests` (e.g., `dumb_treadmill_Watch_AppTests`).
- Run the provided test plan or use the scheme-based `xcodebuild test` command.

## Commit & Pull Request Guidelines
- Commit history is informal and short; keep messages concise and describe the change in plain language (e.g., "Fix timer pause state").
- PRs should include: a brief summary, testing notes, and screenshots or GIFs for UI changes.
- Link relevant issues if they exist.

## Security & Configuration Tips
- HealthKit and workout permissions are configured via `dumb_treadmill Watch App/dumb_treadmill Watch App.entitlements` and `dumb_treadmill Watch App/Info.plist`.
- If you add new HealthKit types or permissions, update both files and verify on device/simulator.
