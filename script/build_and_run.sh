#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TeXSplit"
PROJECT="TeXSplit.xcodeproj"
SCHEME="TeXSplit"
CONFIGURATION="Debug"
DERIVED_DATA="${PWD}/DerivedData"
APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

if pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
  pkill -x "${APP_NAME}" || true
fi

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  build

/usr/bin/open -n "${APP_PATH}"

if [[ "${1:-}" == "--verify" ]]; then
  sleep 2
  pgrep -x "${APP_NAME}" >/dev/null
  echo "${APP_NAME} launched"
fi
