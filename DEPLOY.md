# Shipping Flutter app updates

## Why UI changes sometimes don’t show

- **Hot reload** (`r`) does not re-run `main()` or replace the root widget tree reliably. After changing `main.dart`, shell/navigation, or providers, use **hot restart** (`R` / **Restart**) or **stop and run again**.
- **Installing an old APK/AAB** from before the change will never show new code until you **build and install a new binary**.

## Fast local check

```bash
cd mobile-app
flutter pub get
flutter run
```

Log in: you should see **three** bottom tabs: **Home**, **Support**, **Settings**.

## Build for testers / store

```bash
# Android APK (quick sideload)
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk` and `.../bundle/release/app-release.aab`.

## Faster rollout to testers (not instant OTA)

- **Google Play**: Internal testing track uploads an AAB; testers get the update within minutes after processing.
- **Firebase App Distribution**: upload APK/AAB and invite testers by email.
- Code does **not** auto-update on users’ phones until you publish a new build through a store or distribution channel.
