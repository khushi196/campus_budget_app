import 'expense_store.dart';
import 'expense_store_factory_stub.dart'
    if (dart.library.html) 'expense_store_factory_web.dart';

ExpenseStore createExpenseStore() => createPlatformExpenseStore();
