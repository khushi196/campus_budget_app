import '../data/demo_data.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/income_entry.dart';
import '../models/ledger.dart';
import '../models/piggybank.dart';
import 'expense_store.dart';

class ExpenseService {
  ExpenseService._({
    required List<Expense> baseExpenses,
    required List<CategoryBudget> baseCategories,
    required List<Ledger> baseLedgers,
    required List<Piggybank> basePiggybanks,
    required this._initialTotalSpent,
    required this._initialDailyLimit,
    required this._initialTodaySpending,
    required this._store,
  }) : _baseExpenses = [...baseExpenses],
       _baseCategories = [...baseCategories],
       _baseLedgers = [...baseLedgers],
       _basePiggybanks = [...basePiggybanks] {
    _loadSnapshot(_store.loadSnapshot());
    _recalculate();
  }

  factory ExpenseService.demo({ExpenseStore? store}) {
    return ExpenseService._(
      baseExpenses: DemoData.expenses,
      baseCategories: DemoData.categories,
      baseLedgers: DemoData.ledgers,
      basePiggybanks: DemoData.piggybanks,
      initialTotalSpent: 1915,
      initialDailyLimit: 200,
      initialTodaySpending: 120,
      store: store ?? NoopExpenseStore(),
    );
  }

  final List<Expense> _baseExpenses;
  final List<CategoryBudget> _baseCategories;
  final List<Ledger> _baseLedgers;
  final List<Piggybank> _basePiggybanks;
  final ExpenseStore _store;
  final double _initialTotalSpent;
  final double _initialDailyLimit;
  final double _initialTodaySpending;

  final List<Expense> _addedExpenses = [];
  final List<IncomeEntry> _incomeEntries = [];
  late List<Ledger> _ledgers;
  late List<Piggybank> _piggybanks;
  final Map<String, double> _categoryLimitOverrides = {};
  double? _dailyLimitOverride;

  late List<Expense> _expenses;
  late List<CategoryBudget> _categories;
  late double _addedExpenseTotal;
  late double _addedTodaySpending;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Expense> get addedExpenses => List.unmodifiable(_addedExpenses);
  List<IncomeEntry> get incomeEntries => List.unmodifiable(_incomeEntries);
  List<Ledger> get ledgers => List.unmodifiable(_ledgers);
  List<Piggybank> get piggybanks => List.unmodifiable(_piggybanks);
  List<CategoryBudget> get categories => List.unmodifiable(_categories);
  double get totalSpent => _initialTotalSpent + _addedExpenseTotal;
  double get todaySpending => _initialTodaySpending + _addedTodaySpending;
  double get totalIncome =>
      _incomeEntries.fold<double>(0, (total, entry) => total + entry.amount);
  double get balanceLeft => totalIncome - totalSpent;
  double get dailyLimit => _dailyLimitOverride ?? _initialDailyLimit;
  double get dailyLimitLeft =>
      (dailyLimit - todaySpending).clamp(0, dailyLimit).toDouble();
  double get ledgerBalance =>
      _ledgers.fold<double>(0, (total, ledger) => total + ledger.amount);

  void addExpense(Expense expense) {
    _addedExpenses.insert(0, expense);
    _recalculateAndPersist();
  }

  void updateAddedExpense(int index, Expense expense) {
    if (index < 0 || index >= _addedExpenses.length) {
      return;
    }

    _addedExpenses[index] = expense;
    _recalculateAndPersist();
  }

  void deleteAddedExpense(int index) {
    if (index < 0 || index >= _addedExpenses.length) {
      return;
    }

    _addedExpenses.removeAt(index);
    _recalculateAndPersist();
  }

  void addIncome(IncomeEntry entry) {
    if (entry.amount <= 0) {
      return;
    }

    _incomeEntries.insert(0, entry);
    _persist();
  }

  void deleteIncomeEntry(int index) {
    if (index < 0 || index >= _incomeEntries.length) {
      return;
    }

    _incomeEntries.removeAt(index);
    _persist();
  }

  void addLedger(Ledger ledger) {
    _ledgers.insert(0, ledger);
    _persist();
  }

  void updateLedger(int index, Ledger ledger) {
    if (index < 0 || index >= _ledgers.length) {
      return;
    }

    _ledgers[index] = ledger;
    _persist();
  }

  void deleteLedger(int index) {
    if (index < 0 || index >= _ledgers.length) {
      return;
    }

    _ledgers.removeAt(index);
    _persist();
  }

  void addPiggybank(Piggybank piggybank) {
    _piggybanks.insert(0, piggybank);
    _persist();
  }

  void updatePiggybank(int index, Piggybank piggybank) {
    if (index < 0 || index >= _piggybanks.length) {
      return;
    }

    _piggybanks[index] = piggybank;
    _persist();
  }

  void addToPiggybank(int index, double amount) {
    if (index < 0 || index >= _piggybanks.length || amount <= 0) {
      return;
    }

    final piggybank = _piggybanks[index];
    _piggybanks[index] = Piggybank(
      name: piggybank.name,
      goalAmount: piggybank.goalAmount,
      savedAmount: piggybank.savedAmount + amount,
      dueDate: piggybank.dueDate,
    );
    _persist();
  }

  void withdrawFromPiggybank(int index, double amount) {
    if (index < 0 || index >= _piggybanks.length || amount <= 0) {
      return;
    }

    final piggybank = _piggybanks[index];
    _piggybanks[index] = Piggybank(
      name: piggybank.name,
      goalAmount: piggybank.goalAmount,
      savedAmount: (piggybank.savedAmount - amount)
          .clamp(0, piggybank.savedAmount)
          .toDouble(),
      dueDate: piggybank.dueDate,
    );
    _persist();
  }

  void deletePiggybank(int index) {
    if (index < 0 || index >= _piggybanks.length) {
      return;
    }

    _piggybanks.removeAt(index);
    _persist();
  }

  void setDailyLimit(double limit) {
    if (limit <= 0) {
      return;
    }

    _dailyLimitOverride = limit;
    _persist();
  }

  void setCategoryLimit(String categoryName, double limit) {
    if (limit <= 0) {
      return;
    }

    _categoryLimitOverrides[categoryName] = limit;
    _recalculateAndPersist();
  }

  void clearAddedData() {
    _addedExpenses.clear();
    _categoryLimitOverrides.clear();
    _incomeEntries.clear();
    _ledgers = [..._baseLedgers];
    _piggybanks = [..._basePiggybanks];
    _dailyLimitOverride = null;
    _recalculateAndPersist();
  }

  void _loadSnapshot(ExpenseSnapshot snapshot) {
    _addedExpenses
      ..clear()
      ..addAll(snapshot.addedExpenses);
    _incomeEntries
      ..clear()
      ..addAll(snapshot.incomeEntries);
    _ledgers = snapshot.ledgers ?? [..._baseLedgers];
    _piggybanks = snapshot.piggybanks ?? [..._basePiggybanks];
    _dailyLimitOverride = snapshot.dailyLimit;
    _categoryLimitOverrides
      ..clear()
      ..addAll(snapshot.categoryLimits);
  }

  void _recalculateAndPersist() {
    _recalculate();
    _persist();
  }

  void _recalculate() {
    _expenses = [..._addedExpenses, ..._baseExpenses];
    _addedExpenseTotal = _addedExpenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
    _addedTodaySpending = _addedExpenseTotal;

    _categories = _baseCategories.map((baseCategory) {
      final addedSpent = _addedExpenses
          .where((expense) => expense.category == baseCategory.name)
          .fold<double>(0, (total, expense) => total + expense.amount);

      return CategoryBudget(
        name: baseCategory.name,
        spent: baseCategory.spent + addedSpent,
        limit: _categoryLimitOverrides[baseCategory.name] ?? baseCategory.limit,
      );
    }).toList();
  }

  void _persist() {
    _store.saveSnapshot(
      ExpenseSnapshot(
        addedExpenses: _addedExpenses,
        incomeEntries: _incomeEntries,
        ledgers: _ledgers,
        piggybanks: _piggybanks,
        dailyLimit: _dailyLimitOverride,
        categoryLimits: _categoryLimitOverrides,
      ),
    );
  }
}
