#!/usr/bin/env bash
# Generates the Android/iOS platform folders for FASAL (run once after cloning)
# and applies the small native tweaks the app needs.
#
#   bash tool/setup_platforms.sh
#
# `flutter create .` only creates files that are missing — it never touches lib/.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --project-name fasal --org pk.fasal --platforms android,ios

MANIFEST=android/app/src/main/AndroidManifest.xml
if [ -f "$MANIFEST" ]; then
  # 1) App name shown under the launcher icon.
  sed -i.bak 's/android:label="fasal"/android:label="Fasal"/' "$MANIFEST"

  # 2) Android 11+ package visibility: let flutter_tts find the TTS engine.
  if ! grep -q "android.intent.action.TTS_SERVICE" "$MANIFEST"; then
    if grep -q "</queries>" "$MANIFEST"; then
      sed -i.bak 's#</queries>#    <intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n        </intent>\n    </queries>#' "$MANIFEST"
    else
      sed -i.bak 's#</manifest>#    <queries>\n        <intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n        </intent>\n    </queries>\n</manifest>#' "$MANIFEST"
    fi
  fi
  rm -f "$MANIFEST.bak"
  echo "✔ AndroidManifest patched (label + TTS query)"
fi

# `flutter create` adds a counter-app sample test if none exists — remove it.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
  echo "✔ Removed template test/widget_test.dart"
fi

echo "✔ Platform folders ready. Next: flutter pub get && flutter run"
