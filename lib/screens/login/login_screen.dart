import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

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
                              Expanded(child: _LoginForm(onSignIn: onSignIn)),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                const _BrandPanel(compact: true),
                                _LoginForm(onSignIn: onSignIn),
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

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your campus budget.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
              ),
              const SizedBox(height: 30),
              Text('Email', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'khushi@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Text('Password', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  suffixIcon: Icon(Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(value: true, onChanged: (_) {}),
                  Expanded(
                    child: Text(
                      'Remember me',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
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
                    onPressed: onSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New here?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
