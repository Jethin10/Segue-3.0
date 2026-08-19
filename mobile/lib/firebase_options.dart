import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Replace through `flutterfire configure` for production. The --dart-define
/// values keep credentials outside source control for prototype environments.
class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static bool get isConfigured => _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId:
            String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _projectId,
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        authDomain:
            kIsWeb ? String.fromEnvironment('FIREBASE_AUTH_DOMAIN') : null,
      );
}
