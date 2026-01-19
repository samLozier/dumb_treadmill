#!/bin/bash
set -euo pipefail

SCHEME="dumb_treadmill Watch App"

if [[ -n "${SIMULATOR_ID:-}" ]]; then
    DESTINATION="platform=watchOS Simulator,id=${SIMULATOR_ID}"
elif [[ -n "${SIMULATOR_NAME:-}" ]]; then
    DESTINATION="platform=watchOS Simulator,name=${SIMULATOR_NAME}"
else
    echo "Set SIMULATOR_ID or SIMULATOR_NAME to target a watchOS simulator." >&2
    exit 1
fi

xcodebuild -scheme "${SCHEME}" -destination "${DESTINATION}" \
    -parallel-testing-enabled NO \
    test
