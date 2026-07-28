# Project TITAN 2.0 — Deployment & Release Guide

## Prerequisites
- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.3.0`
- Android SDK 34 / Java 17 (for Android build)
- Chrome / Edge (for Web build)
- Visual Studio 2022 C++ Build Tools (for Windows build)
- Melos CLI (`dart pub global activate melos`)

---

## Release Pipeline Commands

### 1. Execute Release Automation
```bash
dart project_titan/tools/release_automation.dart 2.0.0-beta.1 100
```

### 2. Verify Monorepo
```bash
# Format check
dart format . --set-exit-if-changed

# Static analysis
melos bootstrap
melos analyze
melos test
```

---

## Multi-Platform Target Builds

### 1. Android APK Build
```bash
flutter build apk --release --build-name=2.0.0-beta.1 --build-number=100
```
Artifact location: `build/app/outputs/flutter-apk/app-release.apk`

### 2. Web Production Build
```bash
flutter build web --release --base-href="/"
```
Artifact location: `build/web/`

### 3. Windows Native Build
```bash
flutter build windows --release
```
Artifact location: `build/windows/x64/runner/Release/`

---

## Release Tagging & Verification
```bash
git tag -a v2.0.0-beta.1 -m "Project TITAN Beta Release v2.0.0-beta.1"
git push origin v2.0.0-beta.1
```
