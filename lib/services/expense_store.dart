import 'dart:convert';

import '../models/expense.dart';
import '../models/income_entry.dart';
import '../models/ledger.dart';
import '../models/piggybank.dart';

abstract class ExpenseStore {
  ExpenseSnapshot loadSnapshot();
  void saveSnapshot(ExpenseSnapshot snapshot);
}

class MemoryExpenseStore implements ExpenseStore {
  String? _payload;

  @override
  ExpenseSnapshot loadSnapshot() {
    return decodeSnapshot(_payload);
  }

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {
    _payload = encodeSnapshot(snapshot);
  }
}

class NoopExpenseStore implements ExpenseStore {
  @override
  ExpenseSnapshot loadSnapshot() => const ExpenseSnapshot();

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {}
}

class ExpenseSnapshot {
  const ExpenseSnapshot({
    this.addedExpenses = const [],
    this.incomeEntries = const [],
    this.ledgers,
    this.piggybanks,
    this.dailyLimit,
    this.categoryLimits = const {},
  });

  final List<Expense> addedExpenses;
  final List<IncomeEntry> incomeEntries;
  final List<Ledger>? ledgers;
  final List<Piggybank>? piggybanks;
  final double? dailyLimit;
  final Map<String, double> categoryLimits;

  factory ExpenseSnapshot.fromJson(Map<String, dynamic> json) {
    final limits = <String, double>{};
    final rawLimits = json['categoryLimits'];
    if (rawLimits is Map) {
      for (final entry in rawLimits.entries) {
        final value = entry.value;
        if (value is num) {
          limits[entry.key.toString()] = value.toDouble();
        }
      }
    }

    return ExpenseSnapshot(
      addedExpenses: decodeExpenses(json['addedExpenses']),
      incomeEntries: decodeIncomeEntries(
        json['incomeEntries'] ?? _legacyIncomeEntry(json['totalIncome']),
      ),
      ledgers: json.containsKey('ledgers')
          ? decodeLedgers(json['ledgers'])
          : null,
      piggybanks: json.containsKey('piggybanks')
          ? decodePiggybanks(json['piggybanks'])
          : null,
      dailyLimit: (json['dailyLimit'] as num?)?.toDouble(),
      categoryLimits: limits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addedExpenses': addedExpenses
          .map((expense) => expense.toJson())
          .toList(),
      'incomeEntries': incomeEntries.map((entry) => entry.toJson()).toList(),
      'ledgers': ledgers?.map((ledger) => ledger.toJson()).toList(),
      'piggybanks': piggybanks?.map((piggybank) => piggybank.toJson()).toList(),
      'dailyLimit': dailyLimit,
      'categoryLimits': categoryLimits,
    };
  }
}

List<Ledger> decodeLedgers(Object? decoded) {
  if (decoded is String) {
    if (decoded.trim().isEmpty) {
      return [];
    }
    return decodeLedgers(jsonDecode(decoded));
  }

  if (decoded == null || decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map<String, dynamic>>()
      .map(Ledger.fromJson)
      .toList();
}

List<Piggybank> decodePiggybanks(Object? decoded) {
  if (decoded is String) {
    if (decoded.trim().isEmpty) {
      return [];
    }
    return decodePiggybanks(jsonDecode(decoded));
  }

  if (decoded == null || decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map<String, dynamic>>()
      .map(Piggybank.fromJson)
      .toList();
}

Object? _legacyIncomeEntry(Object? totalIncome) {
  if (totalIncome is! num || totalIncome <= 0) {
    return null;
  }

  return [
    IncomeEntry(
      date: 'Saved',
      source: 'Added money',
      amount: totalIncome.toDouble(),
    ).toJson(),
  ];
}

String encodeSnapshot(ExpenseSnapshot snapshot) {
  return jsonEncode(snapshot.toJson());
}

ExpenseSnapshot decodeSnapshot(String? payload) {
  if (payload == null || payload.trim().isEmpty) {
    return const ExpenseSnapshot();
  }

  final decoded = jsonDecode(payload);
  if (decoded is Map<String, dynamic>) {
    return ExpenseSnapshot.fromJson(decoded);
  }
  if (decoded is List) {
    return ExpenseSnapshot(addedExpenses: decodeExpenses(decoded));
  }

  return const ExpenseSnapshot();
}

List<Expense> decodeExpenses(Object? decoded) {
  if (decoded is String) {
    if (decoded.trim().isEmpty) {
      return [];
    }
    return decodeExpenses(jsonDecode(decoded));
  }

  if (decoded == null) {
    return [];
  }

  if (decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map<String, dynamic>>()
      .map(Expense.fromJson)
      .toList();
}

List<IncomeEntry> decodeIncomeEntries(Object? decoded) {
  if (decoded is String) {
    if (decoded.trim().isEmpty) {
      return [];
    }
    return decodeIncomeEntries(jsonDecode(decoded));
  }

  if (decoded == null || decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map<String, dynamic>>()
      .map(IncomeEntry.fromJson)
      .toList();
}
