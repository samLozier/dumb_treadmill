#!/bin/bash
set -euo pipefail

SCHEME="dumb_treadmill Watch App"

if [[ -n "${SIMULATOR_ID:-}" ]]; then
    DESTINATION="platform=watchOS Simulator,id=${SIMULATOR_ID}"
elif [[ -n "${SIMULATOR_NAME:-}" ]]; then
    DESTINATION="platform=watchOS Simulator,name=${SIMULATOR_NAME}"
else
    DESTINATION="platform=watchOS Simulator,name=Any watchOS Simulator Device"
fi

xcodebuild -scheme "${SCHEME}" -destination "${DESTINATION}" test
