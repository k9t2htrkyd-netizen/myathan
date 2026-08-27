# Athan 2.1 — session handoff

**Date:** 26 Aug 2026  
**Stop point:** Mac menu-bar “Add daily alarm” no longer quits the app; website next-Adhan + inline alarm form match 2.1.1.  
**Workspace:** `/Volumes/My Book/New Project 1`

### 26 Aug — Mac menu bar + website

**Mac (`version2/`, AthanBarV2):** “Add daily alarm” used a SwiftUI `.sheet` + `DatePicker` on a `MenuBarExtra` accessory window, which dismissed/crashed the extra (looked like a full quit). The add-alarm UI is now **inline** in the panel: name, hour/minute pickers (no calendar popover), sound, Cancel/Save. Same save path: `audio.addCustomAlarm`. Next prayer now skips Sunrise / Midnight / First Third / Tahajjud (`playsAdhan` only), matching Android 2.1.1. Rebuild: `version2/build-and-run.sh`. Dist copy: `dist/AthanBarV2.app`.

**Website:** `findNextPrayer()` uses Fajr/Dhuhr/Asr/Maghrib/Isha only. Add daily alarm is an inline form (not `window.prompt`). Download section: Android APK + Mac DMG via GitHub Releases, plus **Add to iPhone** (Safari → Share → Add to Home Screen) with honest copy that Adhan will **not** play in the background. Cache bust `app.js?v=2.1.1-downloads`. Live: `https://myathan.link/` and `#download`.

---

**Previous date:** 16 Aug 2026  
**Stop point:** Android 2.1.1 APK built, crash fixed, next-prayer/Shafi/background/widget tested on Pixel emulator.  
**App:** `athan_app/` (Flutter, package `com.athan.athan`, version **2.1.1+22**)

Pick up here. Do not rebuild from the crashing 2.1.0 APK.

---

## What to install now

| File | Path | Notes |
|---|---|---|
| **Android APK (current)** | `dist/Athan-2.1-android.apk` | Version **2.1.1** (code 22), ~30 MB, built 16 Aug 2026 ~22:25. Includes `libapp.so`. `extractNativeLibs=true`. |
| Old crashing APK | do not use | Original 2.1.0 (code 21, ~39 MB) crashed on real phones. |
| Older working APK | `dist/Athan-android.apk` | Pre-2.1, 55 MB, from earlier in the day. |

On a phone: **uninstall** old Athan 2.1 first, then sideload `dist/Athan-2.1-android.apk`. Allow **notifications** on first launch (needed for background Adhan).

Windows flash drive **MJS** (`/Volumes/MJS`) was wiped to exFAT and given a Windows-only copy of the project (~4.8 MB) plus `README.txt`. Build the `.exe` on a Windows PC:

```bat
cd athan_app
flutter pub get
flutter build windows --release
```

Then compile `athan_app\windows\installer\Athan.iss` in Inno Setup → `dist\Athan-Setup.exe`. Needs Flutter (Windows), VS 2022 Desktop C++, Inno Setup 6.

---

## Done this session

### 1. Android instant crash (real phone)

**Cause:** the 2.1.0 APK was missing `libapp.so` (compiled Dart). Flutter engine started then died:

`VM snapshot invalid` → `Could not create Dart VM` → `Fatal signal 11`

Also: native libs must be extractable. Current APK uses `packaging { jniLibs { useLegacyPackaging = true } }` so `extractNativeLibs=true`. Compressed `.so` files are then OK on real devices.

Reproduced on Pixel 10a emulator (Android 16, 16 KB pages). Emulator can sometimes load a broken APK that a physical phone will not.

### 2. Next prayer was wrong

UI showed **First Third** as next prayer. Secondary times (Sunrise, Midnight, First Third, Tahajjud) were included.

**Fix:** `PrayerController.updateNextAndCountdown()` only uses timings with `playsAdhan` (Fajr, Dhuhr, Asr, Maghrib, Isha). After Isha, next is **tomorrow’s Fajr**.

Verified on emulator ~10:24 PM → Next **Fajr 5:52 AM**, countdown ~07:27:49.

### 3. Shafi / Hanafi toggle wrapping

`SegmentedButton` checkmark + compact density split “Shafi” onto two lines.

**Fix:** full-width button, `showSelectedIcon: false`, `maxLines: 1`. Verified on emulator.

### 4. Background running

`flutter_foreground_task` 10.x. Persistent notification channel `athan_background`. Service type `specialUse|mediaPlayback`, `stopWithTask=false`. Survived going to the home screen on the emulator.

Entry: `lib/background_service.dart` (`athanStartCallback`, `AthanBackground.ensureRunning()`).

### 5. Home-screen widget

Android widget **Athan** (`com.athan.athan.AthanWidgetProvider`): next prayer, time, countdown, location. Tap opens the app.

Add on device: long-press home → Widgets → Athan.

Files:

- `android/app/src/main/kotlin/com/athan/athan/AthanWidgetProvider.kt`
- `android/app/src/main/res/layout/athan_widget.xml`
- `android/app/src/main/res/xml/athan_widget_info.xml`
- `lib/widget_sync.dart`

---

## How to resume (Mac + My Book)

My Book is **exFAT**. Flutter **cannot** run from exFAT (no hard links). SDK lives in an APFS sparse image **on the HDD**:

- Image: `/Volumes/My Book/flutter-sdk.sparseimage`
- Mount: `/Volumes/FlutterSDK/flutter`
- Leftover clone (do not run Flutter from here): `/Volumes/My Book/flutter-sdk`

```bash
hdiutil attach "/Volumes/My Book/flutter-sdk.sparseimage"
export COPYFILE_DISABLE=1
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export FLUTTER_ROOT="/Volumes/FlutterSDK/flutter"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
cd "/Volumes/My Book/New Project 1/athan_app"
find . -name '._*' -delete
flutter build apk --release
cp -f build/app/outputs/flutter-apk/app-release.apk "/Volumes/My Book/New Project 1/dist/Athan-2.1-android.apk"
```

Keep **project + APK outputs on My Book**. Do not rsync the app to `~/athan_apk_build` or `/tmp`. Android SDK / Gradle / pub cache on the Mac internal disk are OK to *execute*.

`android/local.properties`:

- `flutter.sdk=/Volumes/FlutterSDK/flutter`
- `sdk.dir=/Users/mohammad/Library/Android/sdk`

Emulator used: **Pixel_10a** (`adb` at `$HOME/Library/Android/sdk/platform-tools/adb`).

Always `export COPYFILE_DISABLE=1` and delete `._*` files before Gradle. AppleDouble files on exFAT break Android builds.

---

## Build notes (do not regress)

- `compileSdk = 37` (required by `home_widget` → Glance). Platform installed: `android-37.0`. `android.suppressUnsupportedCompileSdk=37` in `gradle.properties`.
- Kotlin JVM 17 for app **and** plugin subprojects (`android/build.gradle.kts`).
- Glance force in `allprojects` if a plugin pulls `glance-appwidget:1.+` alpha that wants API 37+.
- After every APK: confirm `libapp.so` exists for arm64-v8a, armeabi-v7a, x86_64, and `extractNativeLibs` is true (`aapt dump xmltree ... | rg extractNativeLibs` → `0xffffffff`).
- Bump `version:` in `pubspec.yaml` (currently `2.1.1+22`) before the next store/sideload so Android will overwrite.

---

## Not done / next session

- Widget was **registered** on the emulator; it was **not** auto-placed on the home screen (`cmd appwidget` missing on that image). Confirm add-widget on a real phone.
- Background Adhan on a **physical** phone (Nest + local) not verified; only emulator process + notification.
- List UI still checkmarks the *next* Adhan (Fajr after Isha) rather than marking passed prayers. Cosmetic.
- Windows `.exe` not built on this Mac. Use MJS + a Windows PC.
- iOS still unsigned / not a store IPA.
- Release signing still uses **debug** keys (`android/app/build.gradle.kts`).
- `google_fonts` Inter is **not** bundled; runtime fetch. Fine so far, but bundle fonts if offline/release font errors appear.
- Git: most of `athan_app/` is still untracked. Nothing was committed unless asked.

---

## Key code

| Area | File |
|---|---|
| Startup / UI | `athan_app/lib/main.dart` |
| Next prayer | `athan_app/lib/prayer_controller.dart` → `updateNextAndCountdown()` |
| Adhan schedule | `athan_app/lib/audio_controller.dart` (`lastPlayedKey` in prefs so UI + background isolates do not double-play) |
| Background | `athan_app/lib/background_service.dart` |
| Widget Dart | `athan_app/lib/widget_sync.dart` |
| Android widget | `AthanWidgetProvider.kt` + `athan_widget.xml` |
| Manifest | `android/app/src/main/AndroidManifest.xml` |

Application id: `com.athan.athan`  
minSdk 24, targetSdk 36, compileSdk 37.
