import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth.dart';
import 'firebase_options.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
  }
  runApp(const PramaanApp());
}

class PramaanApp extends StatelessWidget {
  const PramaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PRAMAAN',
      theme: pramaanTheme,
      home: DefaultFirebaseOptions.isConfigured
          ? const AuthGate()
          : const FirebaseSetupRequired(),
    );
  }
}

class FirebaseSetupRequired extends StatelessWidget {
  const FirebaseSetupRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const BrandLockup(),
              const SizedBox(height: 44),
              const Icon(Icons.settings_suggest_outlined,
                  color: saffron, size: 46),
              const SizedBox(height: 18),
              const Text('Connect Firebase to continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              const SizedBox(height: 12),
              const Text(
                  'This build is healthy, but no Firebase project is configured. Run flutterfire configure or provide the documented --dart-define values.',
                  style: TextStyle(color: Color(0xFFB8CAD6), height: 1.55)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF102E46),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF29475D))),
                child: const Text('Setup: README.md → Flutter setup',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
