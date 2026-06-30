import 'dart:async';
import 'dart:js_interop';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'backend_expense_store.dart';
import 'expense_store.dart';

@JS('localStorage')
external _LocalStorage get _localStorage;

extension type _LocalStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

/// Returns the best available store:
///   1. [BackendExpenseStore]  — when the C++ server is reachable on :8080
///   2. [BrowserExpenseStore]  — browser localStorage (silent fallback)
///
/// The async probe runs once at startup and resolves within 1 second so the
/// app is never blocked waiting for the backend.
Future<ExpenseStore> createPlatformExpenseStoreAsync() async {
  try {
    final res = await http
        .get(Uri.parse('http://localhost:8080/health'))
        .timeout(const Duration(seconds: 1));
    if (res.statusCode == 200) {
      final store = BackendExpenseStore(ApiService());
      await store.primeCache();
      return store;
    }
  } catch (_) {
    // Server not running — use localStorage
  }
  return BrowserExpenseStore();
}

/// Synchronous entry-point required by the shared factory interface.
/// Returns localStorage immediately; the caller in [app_shell.dart] can
/// optionally await [createPlatformExpenseStoreAsync] for backend support.
ExpenseStore createPlatformExpenseStore() => BrowserExpenseStore();

class BrowserExpenseStore implements ExpenseStore {
  static const _storageKey = 'campus_budget_zero_start_snapshot_v2';

  @override
  ExpenseSnapshot loadSnapshot() {
    return decodeSnapshot(_localStorage.getItem(_storageKey.toJS)?.toDart);
  }

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {
    _localStorage.setItem(_storageKey.toJS, encodeSnapshot(snapshot).toJS);
  }
}
