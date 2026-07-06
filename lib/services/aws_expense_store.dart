import 'aws_budget_api.dart';
import 'expense_store.dart';

enum AwsSyncStatus { idle, loading, syncing, synced, error }

class AwsSyncState {
  const AwsSyncState(this.status, {this.message});

  final AwsSyncStatus status;
  final String? message;
}

/// Persists [ExpenseSnapshot] data through the deployed AWS API.
///
/// The app's store interface is synchronous, so this class mirrors the local
/// backend store: it keeps a local cache and syncs changes in the background.
class AwsExpenseStore implements ExpenseStore {
  AwsExpenseStore(this._api, {this.backupStore, this.onSyncStateChanged});

  final AwsBudgetApi _api;
  final ExpenseStore? backupStore;
  final void Function(AwsSyncState state)? onSyncStateChanged;
  ExpenseSnapshot _cache = const ExpenseSnapshot();
  Future<void> _pendingSync = Future.value();

  Future<void> primeCache() async {
    _cache = backupStore?.loadSnapshot() ?? const ExpenseSnapshot();
    _emit(const AwsSyncState(AwsSyncStatus.loading));
    try {
      final cloudSnapshot = await _api.getSnapshot();
      if (_hasData(cloudSnapshot) || !_hasData(_cache)) {
        _cache = cloudSnapshot;
        backupStore?.saveSnapshot(cloudSnapshot);
      }
      _emit(const AwsSyncState(AwsSyncStatus.synced));
    } catch (error) {
      _emit(AwsSyncState(AwsSyncStatus.error, message: error.toString()));
    }
  }

  @override
  ExpenseSnapshot loadSnapshot() => _cache;

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {
    _cache = snapshot;
    backupStore?.saveSnapshot(snapshot);
    _emit(const AwsSyncState(AwsSyncStatus.syncing));
    _pendingSync = _pendingSync
        .catchError((_) {})
        .then((_) => _api.saveSnapshot(snapshot))
        .then((_) => _emit(const AwsSyncState(AwsSyncStatus.synced)))
        .catchError((error) {
          _emit(AwsSyncState(AwsSyncStatus.error, message: error.toString()));
        });
  }

  void _emit(AwsSyncState state) {
    onSyncStateChanged?.call(state);
  }

  bool _hasData(ExpenseSnapshot snapshot) {
    return snapshot.addedExpenses.isNotEmpty ||
        snapshot.incomeEntries.isNotEmpty ||
        (snapshot.ledgers?.isNotEmpty ?? false) ||
        (snapshot.piggybanks?.isNotEmpty ?? false) ||
        snapshot.dailyLimit != null ||
        snapshot.categoryLimits.isNotEmpty;
  }
}
