#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

WS_URL="${WS_URL:-}"
if [[ -z "$WS_URL" ]]; then
  HOST_IP="${HOST_IP:-10.0.2.2}"
  WS_PORT="${WS_PORT:-8080}"
  WS_URL="ws://${HOST_IP}:${WS_PORT}"
fi

APP="${1:-both}"
BUILD_MODE="${2:-release}"

echo "Building Android APK"
echo "WS_URL=${WS_URL}"
echo "APP=${APP}"
echo "MODE=${BUILD_MODE}"

build_app() {
  local app_dir="$1"
  local name="$2"

  echo ""
  echo "==> ${name}"
  cd "${ROOT}/${app_dir}"

  if [[ ! -d android ]]; then
    flutter create . --project-name "${app_dir}"
  fi

  flutter pub get

  if [[ "$BUILD_MODE" == "debug" ]]; then
    flutter build apk --debug --dart-define="WS_URL=${WS_URL}"
  else
    flutter build apk --release --dart-define="WS_URL=${WS_URL}"
  fi

  local apk
  if [[ "$BUILD_MODE" == "debug" ]]; then
    apk="build/app/outputs/flutter-apk/app-debug.apk"
  else
    apk="build/app/outputs/flutter-apk/app-release.apk"
  fi

  echo "APK: ${ROOT}/${app_dir}/${apk}"
}

case "$APP" in
  one|pulse|chat_app_one)
    build_app "chat_app_one" "PulseChat"
    ;;
  two|nova|chat_app_two)
    build_app "chat_app_two" "NovaChat AI"
    ;;
  both|all)
    build_app "chat_app_one" "PulseChat"
    build_app "chat_app_two" "NovaChat AI"
    ;;
  *)
    echo "Usage: $0 [one|two|both] [release|debug]"
    exit 1
    ;;
esac

echo ""
echo "Done."
echo "Install on device:"
echo "  adb install -r chat_app_one/build/app/outputs/flutter-apk/app-release.apk"
echo "  adb install -r chat_app_two/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Backend must be reachable at ${WS_URL}"
echo "On the host machine: cd websocket_server && npm start"
echo "Phone and computer must be on the same Wi-Fi for physical devices."
