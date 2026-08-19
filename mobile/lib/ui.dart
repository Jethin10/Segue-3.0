import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const ink = Color(0xFF0B1724);
const navy = Color(0xFF071C2F);
const saffron = Color(0xFFF26522);
const paper = Color(0xFFF6F7F4);
const verified = Color(0xFF07854D);
const disputed = Color(0xFFCF3434);
const muted = Color(0xFF66717D);
const line = Color(0xFFDFE4E1);

final pramaanTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(seedColor: saffron),
  appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent),
  cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: line))),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: saffron, width: 1.5)),
  ),
  filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800))),
);

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.dark = true});
  final bool dark;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SATYAK  सत्यक',
              style: TextStyle(
                  color: dark ? Colors.white : ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const Text('Proof, not promises.',
              style: TextStyle(
                  color: saffron, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      );
}

class PramaanHeader extends StatelessWidget implements PreferredSizeWidget {
  const PramaanHeader({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: navy,
        toolbarHeight: preferredSize.height,
        title: const BrandLockup(),
        actions: [
          IconButton(
              tooltip: 'Sign out',
              onPressed: FirebaseAuth.instance.signOut,
              icon: const Icon(Icons.logout, color: Colors.white)),
          const SizedBox(width: 8)
        ],
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'citizen_verified'
        ? verified
        : (status == 'citizen_disputed' ? disputed : saffron);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7)),
      child: Text(humanStatus(status),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

String humanStatus(String raw) =>
    const {
      'reported': 'Reported',
      'assigned': 'Assigned',
      'worker_on_site': 'Worker on site',
      'proof_submitted': 'Awaiting your verification',
      'citizen_verified': 'Verified',
      'citizen_disputed': 'Disputed',
    }[raw] ??
    raw;

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});
  @override
  Widget build(BuildContext context) => ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
          height: 104,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16))));
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_outlined, color: verified, size: 42),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.5))
          ])));
}
