import 'package:flutter_test/flutter_test.dart';

import 'package:campus_budget_app/models/expense.dart';
import 'package:campus_budget_app/models/income_entry.dart';
import 'package:campus_budget_app/models/ledger.dart';
import 'package:campus_budget_app/models/piggybank.dart';
import 'package:campus_budget_app/services/expense_service.dart';
import 'package:campus_budget_app/services/expense_store.dart';

void main() {
  test('adds an expense and updates dashboard values', () {
    final service = ExpenseService.demo();

    service.addExpense(
      const Expense(
        date: 'Today',
        category: 'Food',
        note: 'Campus coffee',
        amount: 150,
      ),
    );

    expect(service.expenses.first.note, 'Campus coffee');
    expect(service.totalSpent, 2065);
    expect(service.todaySpending, 270);
    expect(service.dailyLimitLeft, 0);
    expect(
      service.categories
          .firstWhere((category) => category.name == 'Food')
          .spent,
      770,
    );
  });

  test('loads added expenses from storage', () {
    final store = MemoryExpenseStore();
    final firstService = ExpenseService.demo(store: store);

    firstService.addExpense(
      const Expense(
        date: 'Today',
        category: 'Food',
        note: 'Saved samosa',
        amount: 40,
      ),
    );

    final reloadedService = ExpenseService.demo(store: store);

    expect(reloadedService.expenses.first.note, 'Saved samosa');
    expect(reloadedService.totalSpent, 1955);
    expect(
      reloadedService.categories
          .firstWhere((category) => category.name == 'Food')
          .spent,
      660,
    );
  });

  test('tracks income and balance', () {
    final service = ExpenseService.demo();

    service.addIncome(
      const IncomeEntry(date: 'Today', source: 'Parents', amount: 10000),
    );

    expect(service.totalIncome, 10000);
    expect(service.balanceLeft, 8085);
    expect(service.incomeEntries.first.source, 'Parents');
  });

  test('persists income entries and custom daily limit', () {
    final store = MemoryExpenseStore();
    final firstService = ExpenseService.demo(store: store);

    firstService.addIncome(
      const IncomeEntry(date: 'Today', source: 'Scholarship', amount: 2500),
    );
    firstService.setDailyLimit(450);

    final reloadedService = ExpenseService.demo(store: store);

    expect(reloadedService.incomeEntries.first.source, 'Scholarship');
    expect(reloadedService.totalIncome, 2500);
    expect(reloadedService.dailyLimit, 450);
    expect(reloadedService.dailyLimitLeft, 330);
  });

  test('deletes income entries', () {
    final service = ExpenseService.demo();

    service.addIncome(
      const IncomeEntry(date: 'Today', source: 'Parents', amount: 10000),
    );
    service.deleteIncomeEntry(0);

    expect(service.incomeEntries, isEmpty);
    expect(service.totalIncome, 0);
    expect(service.balanceLeft, -1915);
  });

  test('edits and deletes added expenses', () {
    final service = ExpenseService.demo();
    const original = Expense(
      date: 'Today',
      category: 'Food',
      note: 'Campus coffee',
      amount: 150,
    );

    service.addExpense(original);
    service.updateAddedExpense(
      0,
      const Expense(
        date: 'Today',
        category: 'Stationery',
        note: 'Lab file',
        amount: 90,
      ),
    );

    expect(service.expenses.first.note, 'Lab file');
    expect(service.totalSpent, 2005);
    expect(
      service.categories
          .firstWhere((category) => category.name == 'Stationery')
          .spent,
      370,
    );

    service.deleteAddedExpense(0);

    expect(service.expenses.first.note, isNot('Lab file'));
    expect(service.totalSpent, 1915);
  });

  test('updates limits and clears added local data', () {
    final store = MemoryExpenseStore();
    final service = ExpenseService.demo(store: store);

    service.addExpense(
      const Expense(
        date: 'Today',
        category: 'Food',
        note: 'Saved samosa',
        amount: 40,
      ),
    );
    service.setDailyLimit(500);
    service.setCategoryLimit('Food', 1500);

    expect(service.dailyLimitLeft, 340);
    expect(
      service.categories
          .firstWhere((category) => category.name == 'Food')
          .limit,
      1500,
    );

    service.clearAddedData();

    expect(service.totalSpent, 1915);
    expect(service.totalIncome, 0);
    expect(service.dailyLimitLeft, 80);
    expect(
      service.categories
          .firstWhere((category) => category.name == 'Food')
          .limit,
      1000,
    );
    expect(
      ExpenseService.demo(store: store).expenses.first.note,
      'Lunch near campus',
    );
  });

  test('manages and persists ledgers', () {
    final store = MemoryExpenseStore();
    final service = ExpenseService.demo(store: store);

    service.addLedger(const Ledger(friendName: 'Neha', amount: 300));
    service.updateLedger(0, const Ledger(friendName: 'Neha', amount: -50));

    expect(service.ledgers.first.friendName, 'Neha');
    expect(service.ledgerBalance, 130);

    service.deleteLedger(0);
    expect(
      service.ledgers.any((ledger) => ledger.friendName == 'Neha'),
      isFalse,
    );

    service.addLedger(const Ledger(friendName: 'Neha', amount: 300));
    expect(ExpenseService.demo(store: store).ledgers.first.friendName, 'Neha');
  });

  test('manages and persists piggybanks', () {
    final store = MemoryExpenseStore();
    final service = ExpenseService.demo(store: store);

    service.addPiggybank(
      const Piggybank(
        name: 'Laptop Fund',
        goalAmount: 60000,
        savedAmount: 5000,
        dueDate: '20 Aug',
      ),
    );
    service.addToPiggybank(0, 2000);
    service.withdrawFromPiggybank(0, 1000);
    service.updatePiggybank(
      0,
      const Piggybank(
        name: 'Laptop Fund',
        goalAmount: 65000,
        savedAmount: 6000,
        dueDate: '25 Aug',
      ),
    );

    expect(service.piggybanks.first.name, 'Laptop Fund');
    expect(service.piggybanks.first.savedAmount, 6000);
    expect(service.piggybanks.first.goalAmount, 65000);
    expect(service.piggybanks.first.dueDate, '25 Aug');

    service.deletePiggybank(0);
    expect(
      service.piggybanks.any((piggybank) => piggybank.name == 'Laptop Fund'),
      isFalse,
    );

    service.addPiggybank(
      const Piggybank(
        name: 'Laptop Fund',
        goalAmount: 60000,
        savedAmount: 5000,
        dueDate: '20 Aug',
      ),
    );
    expect(
      ExpenseService.demo(store: store).piggybanks.first.name,
      'Laptop Fund',
    );
  });
}
