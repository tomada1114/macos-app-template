#!/usr/bin/env bash
# The "app actually runs" guarantee (uv-template smoke_test.py analog):
# build Release, verify the code signature, launch the binary, and assert the
# process stays alive. GUI assertions belong to the XCUITest, not here.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="MyApp"
DERIVED_DATA="build/smoke-derived-data"
ALIVE_SECONDS=10

echo "==> Generating Xcode project"
mise exec -- xcodegen generate

echo "==> Building ${APP_NAME} (Release)"
xcodebuild \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -derivedDataPath "${DERIVED_DATA}" \
    build | mise exec -- xcbeautify --quiet

APP_BUNDLE="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"
BINARY="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "==> Verifying code signature"
codesign --verify --verbose=2 "${APP_BUNDLE}"

echo "==> Launching ${APP_NAME} in the background"
"${BINARY}" &
APP_PID=$!

# Poll: the process must stay alive for the whole window; an early crash fails.
for _ in $(seq 1 "${ALIVE_SECONDS}"); do
    sleep 1
    if ! kill -0 "${APP_PID}" 2>/dev/null; then
        wait "${APP_PID}" || STATUS=$?
        echo "SMOKE FAILED: ${APP_NAME} exited early (status ${STATUS:-unknown})" >&2
        exit 1
    fi
done

echo "==> Terminating ${APP_NAME}"
kill "${APP_PID}"
# The app dies by our signal — that exit status is expected, not a failure.
wait "${APP_PID}" 2>/dev/null || true

echo "SMOKE OK: ${APP_NAME} launched and stayed alive"
