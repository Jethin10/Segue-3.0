# SATYAK mobile demo

Flutter application for the SATYAK citizen and field-worker demo. The default
release is fully seeded and runs without Firebase, sign-in, internet, camera or
location permissions.

## Run

```bash
flutter pub get
flutter run
```

Choose **Citizen demo** or **Field worker demo** on the first screen. All
actions remain on the device and reset when the app process is restarted.

## Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Android and iOS host projects include camera and precise-location usage declarations. The worker cannot directly complete work; it must call the trusted Cloud Functions in `../functions`.
