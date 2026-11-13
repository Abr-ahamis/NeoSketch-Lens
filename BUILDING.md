# Build and install SketchLens for Android

## Requirements

- Flutter stable SDK. This project was last built with Flutter 3.47.9 and Dart 3.13.7.
- Android SDK with platform tools and Android SDK Platform 36 installed.
- JDK 17 or newer. The Android Gradle wrapper downloads the pinned Gradle version on the first build.
- A USB-connected Android device with USB debugging enabled, or an Android emulator.

On the development machine used for this project, Flutter is installed at
`$HOME/SDK/flutter` and the Android SDK at `$HOME/Android/Sdk`. Adjust these
paths if your SDKs are elsewhere.

## One-time machine setup

```sh
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/SDK/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
flutter doctor
flutter doctor --android-licenses
```

Accept the Android licenses when prompted. `flutter doctor` should show the
Flutter and Android toolchains as ready. A browser and Linux desktop toolchain
are not needed to build the Android APK.

## Prepare dependencies and Telegram configuration

```sh
cd /home/neo/Pictures/NeoSketch-Lens/app
flutter pub get
```

For the private personal APK only, put `TELEGRAM_BOT_TOKEN` and
`TELEGRAM_CHAT_ID` in `server/.env`. Start the bot in Telegram and use the chat
ID belonging to that same bot. `server/.env` is ignored by Git. The release
helper reads those values through a temporary protected file and embeds them in
the APK, so never share or publish that APK. Do not paste the token into source
code or commit it.

## Build and install

```sh
cd /home/neo/Pictures/NeoSketch-Lens/app
./build_release.sh
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell monkey -p com.abrahamis.sketchlens -c android.intent.category.LAUNCHER 1
```

Or use `flutter install` after the build. The APK is written to
`app/build/app/outputs/flutter-apk/app-release.apk`. Build outputs and package
caches are generated locally and are intentionally excluded from the source
repository; `flutter pub get` and the build recreate them.

The app sends its one-time device/app beacon on first launch. To inspect its
delivery result:

```sh
adb logcat -c
adb shell monkey -p com.abrahamis.sketchlens -c android.intent.category.LAUNCHER 1
sleep 5
adb logcat -d -v time | grep -E 'SketchLens|flutter'
```

The logs report the HTTP/API result without logging the bot token or request
URL. A successful Telegram response is logged as `HTTP 200`.

## Optional server development

The Python server is not required to build or install the Android app. To run
server tests or the optional relay, create a local virtual environment and
install the pinned requirements:

```sh
cd /home/neo/Pictures/NeoSketch-Lens/server
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```
