# Deploying the Android app to Uptodown

This document explains the steps to build a release-signed APK for upload to Uptodown, prepare required metadata, and configure Android-specific settings in this repository.

Prerequisites
- Flutter SDK installed
- Java JDK 11+
- Android SDK & build tools
- An Android keystore (you will create this locally)

1) Create a release keystore (locally, do NOT commit)

```bash
# from mobile-app directory
keytool -genkey -v -keystore ~/paymentnotify-release.jks -keyalg RSA -keysize 2048 -validity 9125 -alias paymentnotify
```

2) Add `android/key.properties` (local, DO NOT COMMIT)
- Copy `android/key.properties.example` -> `android/key.properties` and fill values. `storeFile` should point to the keystore path (relative to android/ or absolute).

3) Build the release APK

```bash
# from mobile-app
flutter pub get
flutter build apk --release
```

- Output APK: `mobile-app/build/app/outputs/flutter-apk/app-release.apk` or use `app-arm64-v8a-release.apk` variants if split per ABI.

4) Verify signing (optional)

```bash
jarsigner -verify -certs build/app/outputs/flutter-apk/app-release.apk
```

5) Prepare metadata for Uptodown
- App title and short description
- Full description (features, privacy summary)
- Version name and code (from `pubspec.yaml` — `version:`)
- Package name: `com.paymentnotify.app` (see `android/app/build.gradle.kts`)
- App icon(s) and screenshots (recommended sizes: 1080x1920 for phones)
- Privacy policy URL (mandatory; add to server or a static site)
- Contact email/support URL

6) Permissions & privacy
- This app requests notification access (native listener) and SMS permissions on Android. In your Uptodown listing and in-app onboarding, clearly explain why these permissions are needed and how users opt-in/out.
- If you plan to distribute via other stores (e.g., Google Play), ensure you follow their sensitive-permissions policies.

7) Testing
- Install the release APK on a test device:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

- Test notification listener flow: enable "Notification access" in Settings → Special app access → Notification access and grant to the app.

8) Upload to Uptodown
- Sign in to Uptodown publisher console and upload the APK and metadata per their uploader.

Notes & best practices
- Keep `android/key.properties` and the keystore out of source control and backups.
- Use a CI pipeline to automate release builds, storing keystore and passwords as encrypted secrets.
- Consider uploading an AAB if you later want Play Store distribution; Uptodown accepts APK files.
