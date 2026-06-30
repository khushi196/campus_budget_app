import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../widgets/add_expense_dialog.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({
    super.key,
    required this.expenseService,
    required this.onDataChanged,
  });

  final ExpenseService expenseService;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Expenses',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review spending entries before they move into cloud storage.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showAddExpenseDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Expense'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _SummaryPill(
                label: 'Total spent',
                value: _formatCurrency(expenseService.totalSpent),
                color: AppColors.teal,
              ),
              _SummaryPill(
                label: 'Today used',
                value: _formatCurrency(expenseService.todaySpending),
                color: AppColors.coral,
              ),
              _SummaryPill(
                label: 'Entries',
                value: '${expenseService.expenses.length}',
                color: AppColors.blue,
              ),
              _SummaryPill(
                label: 'Balance left',
                value: _formatCurrency(expenseService.balanceLeft),
                color: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _IncomeHistoryCard(
            expenseService: expenseService,
            onDelete: (index) {
              expenseService.deleteIncomeEntry(index);
              onDataChanged();
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  ...expenseService.addedExpenses.asMap().entries.map(
                    (entry) => _ExpenseRow(
                      expense: entry.value,
                      addedIndex: entry.key,
                      onEdit: () => _showEditExpenseDialog(context, entry.key),
                      onDelete: () {
                        expenseService.deleteAddedExpense(entry.key);
                        onDataChanged();
                      },
                    ),
                  ),
                  ...expenseService.expenses
                      .skip(expenseService.addedExpenses.length)
                      .map((expense) => _ExpenseRow(expense: expense)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (expense == null) {
      return;
    }

    expenseService.addExpense(expense);
    onDataChanged();
  }

  Future<void> _showEditExpenseDialog(BuildContext context, int index) async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) =>
          AddExpenseDialog(initialExpense: expenseService.addedExpenses[index]),
    );

    if (expense == null) {
      return;
    }

    expenseService.updateAddedExpense(index, expense);
    onDataChanged();
  }

  String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }
}

class _IncomeHistoryCard extends StatelessWidget {
  const _IncomeHistoryCard({
    required this.expenseService,
    required this.onDelete,
  });

  final ExpenseService expenseService;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Income History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  _formatCurrency(expenseService.totalIncome),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expenseService.incomeEntries.isEmpty)
              Text(
                'No money added yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...expenseService.incomeEntries.asMap().entries.map((entry) {
                final income = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              income.source,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(income.date),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(income.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: Key('delete-income-${entry.key}'),
                        tooltip: 'Delete income',
                        onPressed: () => onDelete(entry.key),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    this.addedIndex,
    this.onEdit,
    this.onDelete,
  });

  final Expense expense;
  final int? addedIndex;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.deepTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('${expense.date} - ${expense.category}'),
              ],
            ),
          ),
          Text(
            'Rs. ${expense.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (addedIndex != null) ...[
            const SizedBox(width: 8),
            IconButton(
              key: Key('edit-added-expense-$addedIndex'),
              tooltip: 'Edit expense',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
            ),
            IconButton(
              key: Key('delete-added-expense-$addedIndex'),
              tooltip: 'Delete expense',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
