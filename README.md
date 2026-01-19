# dumb_treadmill

watchOS SwiftUI app for manual treadmill workouts with HealthKit saves.

## Requirements
- Xcode installed with a watchOS simulator runtime.
- A watchOS simulator device created in Xcode.

## Build
```
xcodebuild -scheme "dumb_treadmill Watch App" -destination "generic/platform=watchOS" build
```

## Test
Set a simulator target explicitly:
```
SIMULATOR_ID=1EB65614-B0CF-4501-BA1B-A428ED5E9D74 ./scripts/run-tests.sh
```

Or use a name:
```
SIMULATOR_NAME="Apple Watch SE (40mm) (2nd generation)" ./scripts/run-tests.sh
```

## Local hooks
Enable repo hooks:
```
git config core.hooksPath .githooks
```
