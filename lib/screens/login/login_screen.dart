import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

typedef SignInHandler = Future<void> Function(String email, String password);
typedef SignUpHandler = Future<void> Function(String email, String password);
typedef ConfirmSignUpHandler = Future<void> Function(String email, String code);
typedef ForgotPasswordHandler = Future<void> Function(String email);
typedef ConfirmForgotPasswordHandler =
    Future<void> Function(String email, String code, String newPassword);

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.cloudMode = false,
    this.onDemoSignIn,
    this.onSignIn,
    this.onSignUp,
    this.onConfirmSignUp,
    this.onForgotPassword,
    this.onConfirmForgotPassword,
  });

  final bool cloudMode;
  final VoidCallback? onDemoSignIn;
  final SignInHandler? onSignIn;
  final SignUpHandler? onSignUp;
  final ConfirmSignUpHandler? onConfirmSignUp;
  final ForgotPasswordHandler? onForgotPassword;
  final ConfirmForgotPasswordHandler? onConfirmForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(isWide ? 32 : 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F7FF), Color(0xFFEAFBFF)],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isWide
                        ? Row(
                            children: [
                              const Expanded(child: _BrandPanel()),
                              Expanded(
                                child: _LoginForm(
                                  cloudMode: cloudMode,
                                  onDemoSignIn: onDemoSignIn,
                                  onSignIn: onSignIn,
                                  onSignUp: onSignUp,
                                  onConfirmSignUp: onConfirmSignUp,
                                  onForgotPassword: onForgotPassword,
                                  onConfirmForgotPassword:
                                      onConfirmForgotPassword,
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                const _BrandPanel(compact: true),
                                _LoginForm(
                                  cloudMode: cloudMode,
                                  onDemoSignIn: onDemoSignIn,
                                  onSignIn: onSignIn,
                                  onSignUp: onSignUp,
                                  onConfirmSignUp: onConfirmSignUp,
                                  onForgotPassword: onForgotPassword,
                                  onConfirmForgotPassword:
                                      onConfirmForgotPassword,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 300 : 640),
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.indigo, AppColors.deepTeal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compact
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coral.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Campus Budget',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 26 : 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your campus money, organized.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 26 : 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track spending, budgets, ledgers, savings goals, and AI insights from one dashboard.',
                style: TextStyle(
                  color: Color(0xFFD8E4F0),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 22 : 0),
          const Column(
            children: [
              _PreviewTile(
                icon: Icons.timelapse_rounded,
                label: 'Daily limit left',
                value: 'Rs. 80',
                color: AppColors.coral,
              ),
              SizedBox(height: 12),
              _PreviewTile(
                icon: Icons.savings_rounded,
                label: 'Savings progress',
                value: 'Rs. 3,550',
                color: AppColors.green,
              ),
              SizedBox(height: 12),
              _PreviewTile(
                icon: Icons.auto_awesome_rounded,
                label: 'AI suggestion',
                value: 'Food budget rising',
                color: AppColors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD8E4F0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LoginMode { signIn, signUp, confirm, forgotPassword, resetPassword }

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.cloudMode,
    this.onDemoSignIn,
    this.onSignIn,
    this.onSignUp,
    this.onConfirmSignUp,
    this.onForgotPassword,
    this.onConfirmForgotPassword,
  });

  final bool cloudMode;
  final VoidCallback? onDemoSignIn;
  final SignInHandler? onSignIn;
  final SignUpHandler? onSignUp;
  final ConfirmSignUpHandler? onConfirmSignUp;
  final ForgotPasswordHandler? onForgotPassword;
  final ConfirmForgotPasswordHandler? onConfirmForgotPassword;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  _LoginMode _mode = _LoginMode.signIn;
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isSignIn => _mode == _LoginMode.signIn;
  bool get _isSignUp => _mode == _LoginMode.signUp;
  bool get _isConfirm => _mode == _LoginMode.confirm;
  bool get _isForgot => _mode == _LoginMode.forgotPassword;
  bool get _isReset => _mode == _LoginMode.resetPassword;
  bool get _needsCode => _isConfirm || _isReset;
  bool get _needsPassword => _isSignIn || _isSignUp || _isReset;

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp
        ? 'Create your account'
        : _isConfirm
        ? 'Verify OTP'
        : _isForgot
        ? 'Reset password'
        : _isReset
        ? 'Enter reset OTP'
        : 'Welcome back';
    final subtitle = widget.cloudMode
        ? _cloudSubtitle
        : 'Sign in to manage your campus budget.';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
              ),
              const SizedBox(height: 30),
              Text('Email', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                key: const Key('login-email-field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_loading,
                decoration: const InputDecoration(
                  hintText: 'khushi@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (_needsPassword) ...[
                const SizedBox(height: 18),
                Text(
                  _isReset ? 'New password' : 'Password',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('login-password-field'),
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    suffixIcon: Icon(Icons.visibility_off_outlined),
                  ),
                ),
              ],
              if (_needsCode) ...[
                const SizedBox(height: 18),
                Text(
                  _isReset ? 'Reset OTP code' : 'OTP code',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('login-code-field'),
                  controller: _codeController,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: _isReset
                        ? 'Enter reset OTP from email'
                        : 'Enter OTP from email',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
              ],
              if (_isSignIn) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: _loading ? null : (_) {}),
                    Expanded(
                      child: Text(
                        'Remember me',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _startForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                _StatusBox(message: _error!, isError: true),
              ],
              if (_message != null) ...[
                const SizedBox(height: 14),
                _StatusBox(message: _message!, isError: false),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.coral],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _primaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isSignIn
                        ? 'Do not have an account?'
                        : 'Already have an account?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(_isSignIn ? 'Create account' : 'Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _cloudSubtitle {
    if (_isConfirm) {
      return 'Enter the OTP Cognito sent to your email, then sign in again.';
    }
    if (_isForgot) {
      return 'Enter your email and we will send a password reset OTP.';
    }
    if (_isReset) {
      return 'Enter the reset OTP and choose a new password.';
    }
    if (_isSignUp) {
      return 'Create your student account. We will email you an OTP.';
    }
    return 'Sign in with your AWS Cognito account.';
  }

  String get _primaryLabel {
    if (_isForgot) return 'Send reset OTP';
    if (_isReset) return 'Reset password';
    if (_isConfirm) return 'Verify OTP';
    if (_isSignUp) return 'Send OTP';
    return 'Sign in';
  }

  void _toggleMode() {
    setState(() {
      _mode = _isSignIn ? _LoginMode.signUp : _LoginMode.signIn;
      _error = null;
      _message = null;
    });
  }

  void _startForgotPassword() {
    if (!widget.cloudMode) {
      setState(() {
        _error = 'Password reset is available only in AWS cloud mode.';
        _message = null;
      });
      return;
    }

    setState(() {
      _mode = _LoginMode.forgotPassword;
      _error = null;
      _message = null;
      _passwordController.clear();
      _codeController.clear();
    });
  }

  Future<void> _submit() async {
    if (!widget.cloudMode) {
      if (_isSignIn) {
        widget.onDemoSignIn?.call();
      } else {
        setState(() {
          _error = 'AWS signup is not connected in local demo mode.';
          _message = null;
        });
      }
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final code = _codeController.text.trim();
    final validationError = _validate(email, password, code);
    if (validationError != null) {
      setState(() {
        _error = validationError;
        _message = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      if (_isSignIn) {
        await widget.onSignIn?.call(email, password);
      } else if (_isForgot) {
        await widget.onForgotPassword?.call(email);
        setState(() {
          _mode = _LoginMode.resetPassword;
          _message = 'Reset OTP sent. Check your email.';
        });
      } else if (_isReset) {
        await widget.onConfirmForgotPassword?.call(email, code, password);
        setState(() {
          _mode = _LoginMode.signIn;
          _message = 'Password reset. Please sign in.';
          _codeController.clear();
          _passwordController.clear();
        });
      } else if (_isSignUp) {
        await widget.onSignUp?.call(email, password);
        setState(() {
          _mode = _LoginMode.confirm;
          _message = 'Account created. Check your email for the code.';
        });
      } else {
        await widget.onConfirmSignUp?.call(email, code);
        setState(() {
          _mode = _LoginMode.signIn;
          _message = 'Account verified. Please sign in.';
          _codeController.clear();
          _passwordController.clear();
        });
      }
    } catch (error) {
      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _validate(String email, String password, String code) {
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (_isForgot) {
      return null;
    }
    if (_needsCode && code.isEmpty) {
      return 'Enter the OTP from your email.';
    }
    if (_needsPassword && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('UserNotConfirmedException')) {
      setState(() => _mode = _LoginMode.confirm);
      return 'Please confirm your email before signing in.';
    }
    if (text.contains('NotAuthorizedException')) {
      return 'Incorrect email or password.';
    }
    if (text.contains('UsernameExistsException')) {
      setState(() => _mode = _LoginMode.confirm);
      return 'This account already exists. Enter your confirmation code.';
    }
    return text.replaceFirst(RegExp(r'^[A-Za-z]+Exception: '), '');
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.red : AppColors.green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
