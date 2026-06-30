import '../models/expense.dart';
import '../models/ledger.dart';
import '../models/piggybank.dart';
import 'api_service.dart';
import 'expense_store.dart';

/// Persists [ExpenseSnapshot] data through the C++ HTTP backend.
///
/// The shared [ExpenseStore] interface is synchronous, so this store keeps a
/// local cache and mirrors saves to the backend in the background.
class BackendExpenseStore implements ExpenseStore {
  BackendExpenseStore(this._api);

  final ApiService _api;
  ExpenseSnapshot _cache = const ExpenseSnapshot();

  /// Loads the latest backend state before [loadSnapshot] is used.
  Future<void> primeCache() async {
    try {
      final expenses = await _api.getExpenses();
      final ledgers = await _api.getLedgers();
      final piggybanks = await _api.getPiggybanks();

      _cache = ExpenseSnapshot(
        addedExpenses: expenses.map(Expense.fromJson).toList(),
        ledgers: ledgers.map(Ledger.fromJson).toList(),
        piggybanks: piggybanks.map(Piggybank.fromJson).toList(),
      );
    } catch (_) {
      _cache = const ExpenseSnapshot();
    }
  }

  @override
  ExpenseSnapshot loadSnapshot() => _cache;

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {
    _cache = snapshot;
    _syncToBackend(snapshot);
  }

  Future<void> _syncToBackend(ExpenseSnapshot snapshot) async {
    try {
      await _replaceExpenses(snapshot.addedExpenses);
      await _replaceLedgers(snapshot.ledgers ?? []);
      await _replacePiggybanks(snapshot.piggybanks ?? []);
    } catch (_) {
      // Keep the in-memory cache even if the local backend is not running.
    }
  }

  Future<void> _replaceExpenses(List<Expense> expenses) async {
    await _api.clearExpenses();
    for (final expense in expenses) {
      await _api.addExpense(expense.toJson());
    }
  }

  Future<void> _replaceLedgers(List<Ledger> ledgers) async {
    await _api.clearLedgers();
    for (final ledger in ledgers) {
      await _api.upsertLedger(ledger.friendName, ledger.amount);
    }
  }

  Future<void> _replacePiggybanks(List<Piggybank> piggybanks) async {
    await _api.clearPiggybanks();
    for (final piggybank in piggybanks) {
      await _api.addPiggybank(piggybank.toJson());
    }
  }
}
