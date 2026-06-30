import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single message in the AI chat conversation.
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  /// 'user' or 'model'
  final String role;
  final String text;
}

/// Context object passed to the AI so it can give budget-aware advice.
class BudgetContext {
  const BudgetContext({
    required this.totalSpent,
    required this.totalIncome,
    required this.dailyLimit,
    required this.todaySpending,
    required this.ledgerBalance,
    required this.topCategory,
    required this.savingsGoalCount,
  });

  final double totalSpent;
  final double totalIncome;
  final double dailyLimit;
  final double todaySpending;
  final double ledgerBalance;
  final String topCategory;
  final int savingsGoalCount;
}

/// Gemini-backed AI advisor service.
///
/// Maintains the full conversation history across calls so the model
/// has memory of previous messages within the session.
class GeminiAiService {
  GeminiAiService({
    BudgetContext? initialContext,
    this.backendUrl = defaultBackendUrl,
  }) : _context = initialContext;

  static const defaultModel = 'gemini-flash-lite-latest';
  static const defaultBackendUrl = 'http://localhost:8080';
  static const proxyPath = '/ai/gemini';

  final String backendUrl;

  // Full conversation history sent to Gemini on each call.
  final List<ChatMessage> _history = [];

  BudgetContext? _context;

  List<ChatMessage> get history => List.unmodifiable(_history);

  /// Update the live budget context (called before each send).
  void updateContext(BudgetContext ctx) => _context = ctx;

  /// Send a user message and return the model reply.
  ///
  /// Throws a [GeminiException] on API errors.
  Future<String> send(String userMessage) async {
    _history.add(ChatMessage(role: 'user', text: userMessage));

    final url = Uri.parse('$backendUrl$proxyPath');

    final body = jsonEncode({
      'model': defaultModel,
      'contents': _buildContents(),
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      // Remove the user message we just added on failure
      _history.removeLast();
      throw GeminiException(
        'API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractText(decoded);

    _history.add(ChatMessage(role: 'model', text: text));
    return text;
  }

  /// Clear conversation history (start a new chat session).
  void clearHistory() => _history.clear();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _buildSystemPrompt() {
    final ctx = _context;
    if (ctx == null) {
      return '''You are a friendly and knowledgeable campus budget advisor.
Help college students track expenses, set savings goals, manage shared expenses
with friends, and develop healthy financial habits.
Keep responses concise, practical, and encouraging.
Use ₹ (Indian Rupee) as the currency symbol.''';
    }

    return '''You are a friendly and knowledgeable campus budget advisor for a college student.

CURRENT BUDGET SNAPSHOT:
- Total income added: ₹${ctx.totalIncome.toStringAsFixed(0)}
- Total spent: ₹${ctx.totalSpent.toStringAsFixed(0)}
- Balance left: ₹${(ctx.totalIncome - ctx.totalSpent).toStringAsFixed(0)}
- Today's spending: ₹${ctx.todaySpending.toStringAsFixed(0)} (daily limit: ₹${ctx.dailyLimit.toStringAsFixed(0)})
- Highest spending category: ${ctx.topCategory}
- Net friend ledger balance: ₹${ctx.ledgerBalance.toStringAsFixed(0)} ${ctx.ledgerBalance >= 0 ? "(people owe you)" : "(you owe people)"}
- Active savings goals: ${ctx.savingsGoalCount}

Use this data to give specific, personalised advice. Be conversational and encouraging.
Keep responses concise (2-4 sentences unless asked for more detail).
Use ₹ (Indian Rupee) as the currency symbol.
If the user asks something unrelated to budgeting, gently steer back to finance.''';
  }

  List<Map<String, dynamic>> _buildContents() {
    final list = <Map<String, dynamic>>[];
    final instruction = _buildSystemPrompt();

    for (int i = 0; i < _history.length; i++) {
      final msg = _history[i];
      if (i == 0 && msg.role == 'user') {
        list.add({
          'role': 'user',
          'parts': [
            {'text': '$instruction\n\nUser request: ${msg.text}'},
          ],
        });
      } else {
        list.add({
          'role': msg.role,
          'parts': [
            {'text': msg.text},
          ],
        });
      }
    }
    return list;
  }

  String _extractText(Map<String, dynamic> decoded) {
    try {
      final candidates = decoded['candidates'] as List<dynamic>;
      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      return (parts[0]['text'] as String).trim();
    } catch (_) {
      return 'Sorry, I could not parse the response. Please try again.';
    }
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}
