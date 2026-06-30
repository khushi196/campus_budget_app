import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'widgets/app_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _signedIn = false;

  @override
  Widget build(BuildContext context) {
    if (_signedIn) {
      return const AppShell();
    }

    return LoginScreen(onSignIn: () => setState(() => _signedIn = true));
  }
}
