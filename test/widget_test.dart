import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_budget_app/main.dart';

void main() {
  testWidgets('shows login first and opens dashboard after sign in', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Campus Budget'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsNothing);

    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('AI Budget Advisor'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('Daily limit left'), findsOneWidget);
  });

  testWidgets('adds an expense and updates dashboard totals', (tester) async {
    await tester.pumpWidget(const MyApp());
    await _signIn(tester);

    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '150',
    );
    await tester.enterText(
      find.byKey(const Key('expense-note-field')),
      'Campus coffee',
    );
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Campus coffee'), findsOneWidget);
    expect(find.text('Rs. 2,065'), findsOneWidget);
    expect(find.text('Rs. 770 / 1000'), findsOneWidget);
  });

  testWidgets('sidebar pages show real tracker content', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await _signIn(tester);

    await tester.tap(find.text('Expenses').first);
    await tester.pumpAndSettle();
    expect(find.text('All Expenses'), findsOneWidget);
    expect(find.text('Lunch near campus'), findsOneWidget);

    await tester.tap(find.text('Categories').first);
    await tester.pumpAndSettle();
    expect(find.text('Category Budgets'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);

    await tester.tap(find.text('Ledgers').first);
    await tester.pumpAndSettle();
    expect(find.text('Friend Ledgers'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);

    await tester.tap(find.text('Piggybanks').first);
    await tester.pumpAndSettle();
    expect(find.text('Savings Goals'), findsOneWidget);
    expect(find.text('Semester Books'), findsOneWidget);

    await tester.tap(find.text('Reports').first);
    await tester.pumpAndSettle();
    expect(find.text('Spending Report'), findsOneWidget);
    expect(find.text('Highest category'), findsOneWidget);
  });

  testWidgets('manages income, expenses, limits, and reset controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await _signIn(tester);

    await tester.tap(find.text('Add Money'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('income-amount-field')),
      '10000',
    );
    await tester.tap(find.text('Save Money'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 8,085'), findsOneWidget);

    await tester.tap(find.text('Set Daily Limit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-limit-field')),
      '450',
    );
    await tester.tap(find.text('Save Limit'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 330'), findsOneWidget);

    await tester.tap(find.text('Expenses').first);
    await tester.pumpAndSettle();
    expect(find.text('Income History'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '150',
    );
    await tester.enterText(
      find.byKey(const Key('expense-note-field')),
      'Campus coffee',
    );
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Campus coffee'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-added-expense-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '90');
    await tester.enterText(
      find.byKey(const Key('expense-note-field')),
      'Lab file',
    );
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Lab file'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-added-expense-0')));
    await tester.pumpAndSettle();
    expect(find.text('Lab file'), findsNothing);

    await tester.tap(find.text('Categories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-limit-Food')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-limit-field')),
      '1500',
    );
    await tester.tap(find.text('Save Limit'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 620 used, Rs. 880 left'), findsOneWidget);

    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. -1,915'), findsOneWidget);
    expect(find.text('Rs. 1,915'), findsOneWidget);
  });

  testWidgets('manages ledgers and piggybank goals from their pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await _signIn(tester);

    await tester.tap(find.text('Ledgers').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Ledger'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ledger-name-field')), 'Neha');
    await tester.enterText(find.byKey(const Key('ledger-amount-field')), '300');
    await tester.tap(find.text('Save Ledger'));
    await tester.pumpAndSettle();
    expect(find.text('Neha'), findsOneWidget);
    expect(find.text('Rs. 480'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-ledger-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ledger-amount-field')), '-50');
    await tester.tap(find.text('Save Ledger'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 130'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-ledger-0')));
    await tester.pumpAndSettle();
    expect(find.text('Neha'), findsNothing);

    await tester.tap(find.text('Piggybanks').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Goal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('piggybank-name-field')),
      'Laptop Fund',
    );
    await tester.enterText(
      find.byKey(const Key('piggybank-goal-field')),
      '60000',
    );
    await tester.enterText(
      find.byKey(const Key('piggybank-saved-field')),
      '5000',
    );
    await tester.enterText(
      find.byKey(const Key('piggybank-date-field')),
      '20 Aug',
    );
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop Fund'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-piggybank-money-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('piggybank-amount-field')),
      '2000',
    );
    await tester.tap(find.text('Save Amount'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 7000 saved of Rs. 60000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('withdraw-piggybank-money-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('piggybank-amount-field')),
      '1000',
    );
    await tester.tap(find.text('Save Amount'));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 6000 saved of Rs. 60000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-piggybank-0')));
    await tester.pumpAndSettle();
    expect(find.text('Laptop Fund'), findsNothing);
  });
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sign in'));
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}
