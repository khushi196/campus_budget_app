import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../models/category_budget.dart';
import '../../models/expense.dart';
import '../../models/income_entry.dart';
import '../../models/ledger.dart';
import '../../models/piggybank.dart';
import '../../services/expense_service.dart';
import '../../widgets/add_expense_dialog.dart';
import '../../widgets/ai_advisor_panel.dart';
import '../../widgets/expense_table.dart';
import '../../widgets/money_dialogs.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.expenseService,
    required this.onDataChanged,
  });

  final ExpenseService expenseService;
  final VoidCallback onDataChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final expenseService = widget.expenseService;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showDailyLimitDialog,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Set Daily Limit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _showAddIncomeDialog,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Add Money'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Track daily spending, friend balances, savings goals, and AI insights.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 720
                  ? 2
                  : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.28,
                children: [
                  StatCard(
                    title: 'Balance left',
                    value: _formatCurrency(expenseService.balanceLeft),
                    caption:
                        '${_formatCurrency(expenseService.totalIncome)} added money',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.green,
                  ),
                  StatCard(
                    title: 'Total spent',
                    value: _formatCurrency(expenseService.totalSpent),
                    caption: 'Across 4 categories',
                    icon: Icons.payments_rounded,
                    color: AppColors.teal,
                  ),
                  StatCard(
                    title: 'Daily limit left',
                    value: _formatCurrency(expenseService.dailyLimitLeft),
                    caption:
                        '${_formatCurrency(expenseService.todaySpending)} used today',
                    icon: Icons.timelapse_rounded,
                    color: AppColors.coral,
                  ),
                  StatCard(
                    title: 'Ledger balance',
                    value: _formatCurrency(expenseService.ledgerBalance),
                    caption: 'Net amount receivable',
                    icon: Icons.group_rounded,
                    color: AppColors.blue,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1040) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          ExpenseTable(
                            expenses: expenseService.expenses,
                            onAddExpense: _showAddExpenseDialog,
                          ),
                          const SizedBox(height: 18),
                          _BudgetAndGoalsSection(
                            categories: expenseService.categories,
                            ledgers: expenseService.ledgers,
                            piggybanks: expenseService.piggybanks,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      flex: 4,
                      child: AiAdvisorPanel(insights: DemoData.insights),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  ExpenseTable(
                    expenses: expenseService.expenses,
                    onAddExpense: _showAddExpenseDialog,
                  ),
                  const SizedBox(height: 18),
                  _BudgetAndGoalsSection(
                    categories: expenseService.categories,
                    ledgers: expenseService.ledgers,
                    piggybanks: expenseService.piggybanks,
                  ),
                  const SizedBox(height: 18),
                  const AiAdvisorPanel(insights: DemoData.insights),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog() async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (expense == null) {
      return;
    }

    widget.expenseService.addExpense(expense);
    widget.onDataChanged();
  }

  Future<void> _showAddIncomeDialog() async {
    final income = await showDialog<IncomeEntry>(
      context: context,
      builder: (context) => const AddIncomeDialog(),
    );

    if (income == null) {
      return;
    }

    widget.expenseService.addIncome(income);
    widget.onDataChanged();
  }

  Future<void> _showDailyLimitDialog() async {
    final limit = await showDialog<double>(
      context: context,
      builder: (context) => EditLimitDialog(
        title: 'Set daily limit',
        initialLimit: widget.expenseService.dailyLimit,
      ),
    );

    if (limit == null) {
      return;
    }

    widget.expenseService.setDailyLimit(limit);
    widget.onDataChanged();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
          'Clear added expenses, added money, and custom limits?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    widget.expenseService.clearAddedData();
    widget.onDataChanged();
  }

  String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }
}

class _BudgetAndGoalsSection extends StatelessWidget {
  const _BudgetAndGoalsSection({
    required this.categories,
    required this.ledgers,
    required this.piggybanks,
  });

  final List<CategoryBudget> categories;
  final List<Ledger> ledgers;
  final List<Piggybank> piggybanks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _CategoryBudgetCard(categories: categories)),
              const SizedBox(width: 18),
              Expanded(
                child: _MoneyMovementCard(
                  ledgers: ledgers,
                  piggybanks: piggybanks,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _CategoryBudgetCard(categories: categories),
            const SizedBox(height: 18),
            _MoneyMovementCard(ledgers: ledgers, piggybanks: piggybanks),
          ],
        );
      },
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({required this.categories});

  final List<CategoryBudget> categories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Budgets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              return _BudgetProgress(category: category);
            }),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({required this.category});

  final CategoryBudget category;

  @override
  Widget build(BuildContext context) {
    final color = category.progress > 0.75 ? AppColors.coral : AppColors.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                'Rs. ${category.spent.toStringAsFixed(0)} / ${category.limit.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: category.progress,
              minHeight: 9,
              backgroundColor: AppColors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyMovementCard extends StatelessWidget {
  const _MoneyMovementCard({required this.ledgers, required this.piggybanks});

  final List<Ledger> ledgers;
  final List<Piggybank> piggybanks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Money Movement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Ledgers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...ledgers.map((ledger) => _LedgerRow(ledger: ledger)),
            const SizedBox(height: 16),
            Text('Piggybanks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...piggybanks.map(
              (piggybank) => _PiggybankRow(piggybank: piggybank),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.ledger});

  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final color = ledger.theyOweYou ? AppColors.green : AppColors.red;
    final label = ledger.theyOweYou ? 'owes you' : 'you owe';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(ledger.friendName)),
          Text(
            '$label Rs. ${ledger.amount.abs().toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PiggybankRow extends StatelessWidget {
  const _PiggybankRow({required this.piggybank});

  final Piggybank piggybank;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  piggybank.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                piggybank.dueDate,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: piggybank.progress,
              minHeight: 9,
              backgroundColor: AppColors.border,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs. ${piggybank.savedAmount.toStringAsFixed(0)} of ${piggybank.goalAmount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
