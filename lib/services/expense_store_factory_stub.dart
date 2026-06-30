import 'expense_store.dart';

ExpenseStore createPlatformExpenseStore() => NoopExpenseStore();

Future<ExpenseStore> createPlatformExpenseStoreAsync() async => NoopExpenseStore();
