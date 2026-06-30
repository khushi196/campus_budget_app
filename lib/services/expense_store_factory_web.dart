import 'dart:js_interop';

import 'expense_store.dart';

@JS('localStorage')
external _LocalStorage get _localStorage;

extension type _LocalStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

ExpenseStore createPlatformExpenseStore() => BrowserExpenseStore();

class BrowserExpenseStore implements ExpenseStore {
  static const _storageKey = 'campus_budget_added_expenses';

  @override
  ExpenseSnapshot loadSnapshot() {
    return decodeSnapshot(_localStorage.getItem(_storageKey.toJS)?.toDart);
  }

  @override
  void saveSnapshot(ExpenseSnapshot snapshot) {
    _localStorage.setItem(_storageKey.toJS, encodeSnapshot(snapshot).toJS);
  }
}
