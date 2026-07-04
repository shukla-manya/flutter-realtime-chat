#!/bin/bash
set -euo pipefail
LOGDIR="/Users/manyashukla/flutter-realtime-chat/apks"
mkdir -p "$LOGDIR"
exec > "$LOGDIR/build.log" 2>&1
echo "BUILD_START $(date)"

unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy \
      SOCKS_PROXY SOCKS5_PROXY socks_proxy socks5_proxy \
      GIT_HTTP_PROXY GIT_HTTPS_PROXY DYLD_INSERT_LIBRARIES || true

export JAVA_HOME="/Users/manyashukla/dev-tools/jdk-17.0.15+6/Contents/Home"
export ANDROID_HOME="/Users/manyashukla/dev-tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export FLUTTER_ROOT="/Users/manyashukla/flutter-realtime-chat/.tools/flutter"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
export FLUTTER_PREBUILT_ENGINE_VERSION="dd93de6fb1776398bf586cbd477deade1391c7e4"

bash /Users/manyashukla/flutter-realtime-chat/scripts/build_apks_local.sh
echo "BUILD_SUCCESS $(date)"
echo 0 > "$LOGDIR/build_exit_code.txt"
