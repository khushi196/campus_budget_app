import 'dart:convert';

import 'package:http/http.dart' as http;

import 'expense_store.dart';

class AwsBudgetApi {
  AwsBudgetApi({
    required this.baseUrl,
    required this.idToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String idToken;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  };

  Future<ExpenseSnapshot> getSnapshot() async {
    final response = await _client
        .get(_uri('/snapshot'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _check(response);
    return ExpenseSnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> saveSnapshot(ExpenseSnapshot snapshot) async {
    final response = await _client
        .put(
          _uri('/snapshot'),
          headers: _headers,
          body: jsonEncode(snapshot.toJson()),
        )
        .timeout(const Duration(seconds: 30));
    _check(response);
  }

  Future<Map<String, dynamic>> getReportSummary() async {
    final response = await _client
        .get(_uri('/reports/summary'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> askAi(Map<String, dynamic> payload) async {
    final response = await _client
        .post(_uri('/ai/gemini'), headers: _headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 45));
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Uri _uri(String path) {
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');
  }

  void _check(http.Response response) {
    if (response.statusCode >= 400) {
      throw AwsBudgetApiException(
        'AWS API error ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class AwsBudgetApiException implements Exception {
  const AwsBudgetApiException(this.message);

  final String message;

  @override
  String toString() => 'AwsBudgetApiException: $message';
}
