import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'services/aws_auth_service.dart';
import 'services/aws_config.dart';
import 'services/aws_session_store.dart';
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
  AwsSession? _session;
  late final AwsSessionStore _sessionStore = createAwsSessionStore();

  late final AwsAuthService? _authService = AwsConfig.isConfigured
      ? AwsAuthService(
          region: AwsConfig.region,
          userPoolClientId: AwsConfig.userPoolClientId,
        )
      : null;

  @override
  void initState() {
    super.initState();
    if (!AwsConfig.isConfigured) {
      return;
    }

    final restoredSession = _sessionStore.loadSession();
    if (restoredSession != null) {
      _signedIn = true;
      _session = restoredSession;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) {
      return AppShell(awsSession: _session, onSignOut: _signOut);
    }

    return LoginScreen(
      cloudMode: AwsConfig.isConfigured,
      onDemoSignIn: _demoSignIn,
      onSignIn: _signIn,
      onSignUp: _signUp,
      onConfirmSignUp: _confirmSignUp,
      onForgotPassword: _forgotPassword,
      onConfirmForgotPassword: _confirmForgotPassword,
    );
  }

  void _demoSignIn() {
    setState(() {
      _signedIn = true;
      _session = null;
    });
  }

  Future<void> _signIn(String email, String password) async {
    final auth = _authService;
    if (auth == null) {
      _demoSignIn();
      return;
    }

    final session = await auth.signIn(email: email, password: password);
    _sessionStore.saveSession(session);
    if (!mounted) return;
    setState(() {
      _signedIn = true;
      _session = session;
    });
  }

  Future<void> _signUp(String email, String password) async {
    await _authService?.signUp(email: email, password: password);
  }

  Future<void> _confirmSignUp(String email, String code) async {
    await _authService?.confirmSignUp(email: email, code: code);
  }

  Future<void> _forgotPassword(String email) async {
    await _authService?.forgotPassword(email: email);
  }

  Future<void> _confirmForgotPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await _authService?.confirmForgotPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  void _signOut() {
    _sessionStore.clearSession();
    setState(() {
      _signedIn = false;
      _session = null;
    });
  }
}
