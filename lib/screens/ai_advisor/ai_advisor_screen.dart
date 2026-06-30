import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/ai_service.dart';
import '../../services/expense_service.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key, required this.expenseService});

  final ExpenseService expenseService;

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen>
    with TickerProviderStateMixin {
  late final GeminiAiService _aiService;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  String? _errorMessage;

  // Typing indicator animation
  late final AnimationController _dotController;

  static const _suggestedPrompts = [
    '📊 Analyze my spending this month',
    '💡 How can I save more money?',
    '🎯 Am I on track with my budget?',
    '👥 Help me understand my friend balances',
    '🐷 Tips to reach my savings goals faster',
    '📅 What should my daily budget be?',
  ];

  @override
  void initState() {
    super.initState();

    _aiService = GeminiAiService(initialContext: _buildContext());

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  BudgetContext _buildContext() {
    final svc = widget.expenseService;
    final top = svc.categories.isEmpty
        ? 'N/A'
        : (List.from(
            svc.categories,
          )..sort((a, b) => b.spent.compareTo(a.spent))).first.name;

    return BudgetContext(
      totalSpent: svc.totalSpent,
      totalIncome: svc.totalIncome,
      dailyLimit: svc.dailyLimit,
      todaySpending: svc.todaySpending,
      ledgerBalance: svc.ledgerBalance,
      topCategory: top,
      savingsGoalCount: svc.piggybanks.length,
    );
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    _aiService.updateContext(_buildContext());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _scrollToBottom();

    try {
      await _aiService.send(text);
    } on GeminiException catch (e) {
      setState(() {
        _errorMessage = _cleanErrorMessage(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Network error. Make sure you are connected to the internet.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearChat() {
    setState(() {
      _aiService.clearHistory();
      _errorMessage = null;
    });
  }

  String _cleanErrorMessage(String message) {
    if (message.contains('API_KEY_INVALID')) {
      return 'Invalid Gemini API key. Check GEMINI_API_KEY in the C++ backend terminal.';
    }

    try {
      final start = message.indexOf('{');
      if (start != -1) {
        final jsonStr = message.substring(start);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map && decoded['error'] is Map) {
          final error = decoded['error'] as Map;
          if (error.containsKey('message')) {
            return 'Error: ${error['message']}';
          }
        }
      }
    } catch (_) {}

    if (message.contains('RESOURCE_EXHAUSTED')) {
      return 'Quota exceeded (429). Please check your Gemini billing details or try again in a minute.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(onClear: _clearChat, messageCount: _aiService.history.length),
        
        Expanded(
          child: _aiService.history.isEmpty && !_isLoading
              ? _WelcomeView(
                  prompts: _suggestedPrompts,
                  onPrompt: (p) => _send(p),
                )
              : _ChatList(
                  messages: _aiService.history,
                  isLoading: _isLoading,
                  dotController: _dotController,
                  scrollController: _scrollController,
                ),
        ),
        if (_errorMessage != null)
          _ErrorBar(
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
        _InputBar(
          controller: _controller,
          isLoading: _isLoading,
          onSend: _send,
        ),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClear, required this.messageCount});

  final VoidCallback onClear;
  final int messageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.violet, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Budget Advisor',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Powered by Gemini Flash-Lite',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
          const Spacer(),
          if (messageCount > 0)
            Tooltip(
              message: 'Clear chat history',
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('New Chat'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mutedInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Backend AI status banner ─────────────────────────────────────────────────



// ── Welcome / suggested prompts ──────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final void Function(String) onPrompt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.violet, AppColors.blue],
            ).createShader(bounds),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hello! I\'m your campus budget advisor.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'I have live access to your spending data. Ask me anything about '
            'your budget, savings goals, or how to manage money better.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 32),
          Text(
            'Suggested questions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: prompts
                .map((p) => _SuggestionChip(label: p, onTap: () => onPrompt(p)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.violet.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border.all(
              color: _hovered ? AppColors.violet : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? AppColors.violet : AppColors.ink,
              fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chat message list ────────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.messages,
    required this.isLoading,
    required this.dotController,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final AnimationController dotController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _TypingBubble(controller: dotController);
        }
        final msg = messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_AiAvatar(), const SizedBox(width: 10)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.violet, AppColors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : AppColors.ink,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 10), _UserAvatar()],
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.coral.withValues(alpha: 0.16),
      child: const Text(
        'K',
        style: TextStyle(
          color: AppColors.coral,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AiAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (controller.value - i * 0.2).clamp(0.0, 1.0);
                    final opacity = (0.3 + 0.7 * _pingPong(t)).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.violet,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static double _pingPong(double t) => t < 0.5 ? 2 * t : 2 * (1 - t);
}

// ── Error bar ────────────────────────────────────────────────────────────────

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 120),
      color: AppColors.red.withValues(alpha: 0.10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 12),
            child: Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.red,
            ),
            tooltip: 'Dismiss',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function([String?]) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText: 'Ask about your budget…',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.violet,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(isLoading: isLoading, onSend: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.isLoading, required this.onSend});

  final bool isLoading;
  final Future<void> Function([String?]) onSend;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.violet, AppColors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered && !widget.isLoading
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: IconButton(
          onPressed: widget.isLoading ? null : () => widget.onSend(),
          icon: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
