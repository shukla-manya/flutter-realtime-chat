#!/usr/bin/env bash
set -euo pipefail

export JAVA_HOME="/Users/manyashukla/dev-tools/jdk-17.0.15+6/Contents/Home"
export ANDROID_HOME="/Users/manyashukla/dev-tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export FLUTTER_ROOT="/Users/manyashukla/flutter-realtime-chat/.tools/flutter"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
export FLUTTER_PREBUILT_ENGINE_VERSION="dd93de6fb1776398bf586cbd477deade1391c7e4"
# Clear Cursor sandbox proxy if inherited
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy \
      SOCKS_PROXY SOCKS5_PROXY socks_proxy socks5_proxy \
      GIT_HTTP_PROXY GIT_HTTPS_PROXY || true

ROOT="/Users/manyashukla/flutter-realtime-chat"
WS_URL="wss://flutter-realtime-chat.onrender.com"
LOG="$ROOT/scripts/build_apks.log"

exec > >(tee "$LOG") 2>&1

echo "=== Flutter version ==="
flutter --version
echo "3.32.5" > "$FLUTTER_ROOT/version"

GRADLE_DIST="/Users/manyashukla/.gradle/wrapper/dists/gradle-8.12-all/bm591p7ru188z8nkqq84epxyh"
mkdir -p "$GRADLE_DIST"
if [[ ! -d "$GRADLE_DIST/gradle-8.12" ]]; then
  unzip -q -o /Users/manyashukla/dev-tools/gradle-8.12-all.zip -d "$GRADLE_DIST"
fi
chmod +x "$GRADLE_DIST/gradle-8.12/bin/gradle" || true
touch "$GRADLE_DIST/gradle-8.12-all.zip.ok"
if [[ ! -f "$GRADLE_DIST/gradle-8.12-all.zip" ]]; then
  cp /Users/manyashukla/dev-tools/gradle-8.12-all.zip "$GRADLE_DIST/"
fi

build_one() {
  local app="$1"
  local name="$2"
  echo ""
  echo "=== Building $name ($app) ==="
  cd "$ROOT/$app"
  if [[ ! -d android ]]; then
    flutter create . --project-name "$app"
  fi
  sed -i '' 's|distributionUrl=.*|distributionUrl=file\\:///Users/manyashukla/dev-tools/gradle-8.12-all.zip|' \
    android/gradle/wrapper/gradle-wrapper.properties
  # Ensure clean gradle.properties for normal Mac builds
  if [[ -f android/gradle.properties ]]; then
    # Drop sandbox-only java.home / proxy overrides if present
    grep -v 'org.gradle.java.home=\|systemProp.http.proxy\|systemProp.https.proxy\|systemProp.http.nonProxy\|systemProp.https.nonProxy' \
      android/gradle.properties > android/gradle.properties.tmp || true
    mv android/gradle.properties.tmp android/gradle.properties
  fi
  flutter pub get
  flutter build apk --release --dart-define="WS_URL=${WS_URL}"
  echo "APK: $ROOT/$app/build/app/outputs/flutter-apk/app-release.apk"
  ls -lh "$ROOT/$app/build/app/outputs/flutter-apk/app-release.apk"
}

build_one chat_app_one "PulseChat"
build_one chat_app_two "NovaChat AI"

mkdir -p "$ROOT/apks"
cp "$ROOT/chat_app_one/build/app/outputs/flutter-apk/app-release.apk" "$ROOT/apks/PulseChat.apk"
cp "$ROOT/chat_app_two/build/app/outputs/flutter-apk/app-release.apk" "$ROOT/apks/NovaChatAI.apk"
echo ""
echo "DONE"
ls -lh "$ROOT/apks/"
