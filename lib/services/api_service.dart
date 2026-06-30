import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the Campus Budget C++ backend API.
///
/// The server must be running at [baseUrl] (default: http://localhost:8080).
/// All methods return decoded JSON or throw an [ApiException] on failure.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8080'});

  final String baseUrl;

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final res = await _get('/expenses');
    return (res as List).cast<Map<String, dynamic>>();
  }

  /// Returns the assigned ID from the backend.
  Future<int> addExpense(Map<String, dynamic> expense) async {
    final res = await _post('/expenses', expense);
    return res['id'] as int;
  }

  Future<void> updateExpense(int id, Map<String, dynamic> expense) =>
      _put('/expenses/$id', expense);

  Future<void> deleteExpense(int id) => _delete('/expenses/$id');

  Future<void> clearExpenses() => _delete('/expenses');

  // ---------------------------------------------------------------------------
  // Ledgers
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLedgers() async {
    final res = await _get('/ledgers');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> upsertLedger(String friendName, double amount) =>
      _post('/ledgers', {'friendName': friendName, 'amount': amount});

  Future<void> deleteLedger(String friendName) =>
      _delete('/ledgers/$friendName');

  Future<void> clearLedgers() => _delete('/ledgers');

  // ---------------------------------------------------------------------------
  // Piggybanks
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPiggybanks() async {
    final res = await _get('/piggybanks');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<int> addPiggybank(Map<String, dynamic> piggybank) async {
    final res = await _post('/piggybanks', piggybank);
    return res['id'] as int;
  }

  Future<void> updatePiggybank(int id, Map<String, dynamic> piggybank) =>
      _put('/piggybanks/$id', piggybank);

  Future<void> deletePiggybank(int id) => _delete('/piggybanks/$id');

  Future<void> clearPiggybanks() => _delete('/piggybanks');

  Future<void> deposit(int id, double amount) =>
      _post('/piggybanks/$id/deposit', {'amount': amount});

  Future<void> withdraw(int id, double amount) =>
      _post('/piggybanks/$id/withdraw', {'amount': amount});

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _get('/reports/summary');
    return res as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  Future<bool> isServerReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<dynamic> _get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    );
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkStatus(res);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  Future<void> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkStatus(res);
  }

  Future<void> _delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    );
    _checkStatus(res);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
