import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'citizen.dart';
import 'ui.dart';
import 'worker.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (auth.data == null) return const DemoLogin();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future:
              FirebaseFirestore.instance.doc('users/${auth.data!.uid}').get(),
          builder: (context, profile) {
            if (profile.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (profile.hasError || !profile.hasData || !profile.data!.exists) {
              return const MissingProfile();
            }
            return profile.data!.data()?['role'] == 'worker'
                ? const WorkerHome()
                : const CitizenHome();
          },
        );
      },
    );
  }
}

class DemoLogin extends StatefulWidget {
  const DemoLogin({super.key});
  @override
  State<DemoLogin> createState() => _DemoLoginState();
}

class _DemoLoginState extends State<DemoLogin> {
  bool loading = false;
  String? error;

  Future<void> login(String role) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '$role@pramaan.demo',
        password: 'PramaanDemo!2026',
      );
    } on FirebaseAuthException catch (exception) {
      setState(() => error = exception.message ?? 'Sign-in failed.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const BrandLockup(),
              const SizedBox(height: 44),
              const Text('Choose your demo role',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'Use the seeded accounts to run the complete civic proof flow.',
                  style: TextStyle(color: Color(0xFFB8CAD6), height: 1.45)),
              const SizedBox(height: 22),
              FilledButton.icon(
                  onPressed: loading ? null : () => login('citizen'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as citizen')),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: loading ? null : () => login('worker'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: ink),
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Continue as Worker 019'),
              ),
              if (loading)
                const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: LinearProgressIndicator(color: saffron)),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error!,
                        style: const TextStyle(color: Colors.redAccent))),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class MissingProfile extends StatelessWidget {
  const MissingProfile({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: const EmptyMessage(
            message:
                'Your account has no PRAMAAN role profile. Run the demo seed script, then sign in again.'),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: FilledButton(
                    onPressed: FirebaseAuth.instance.signOut,
                    child: const Text('Sign out')))),
      );
}
