import 'package:flutter/material.dart';

import 'demo.dart';
import 'ui.dart';

void main() => runApp(const SatyakApp());

class SatyakApp extends StatelessWidget {
  const SatyakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SATYAK',
      theme: pramaanTheme,
      home: const DemoRoleChooser(),
    );
  }
}
