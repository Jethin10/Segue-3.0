# PRAMAAN mobile

Flutter application for the citizen and field-worker PRAMAAN experiences.

## Run

```bash
flutter pub get
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

For a normal Firebase-native configuration, install FlutterFire CLI and run:

```bash
flutterfire configure
```

The app shows a recoverable configuration screen instead of crashing when Firebase settings are absent.

## Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Android and iOS host projects include camera and precise-location usage declarations. The worker cannot directly complete work; it must call the trusted Cloud Functions in `../functions`.
