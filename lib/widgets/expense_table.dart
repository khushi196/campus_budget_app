import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/expense.dart';

class ExpenseTable extends StatelessWidget {
  const ExpenseTable({super.key, required this.expenses, this.onAddExpense});

  final List<Expense> expenses;
  final VoidCallback? onAddExpense;

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
                  'Recent Expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddExpense,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: expenses
                        .map((expense) => _ExpenseListTile(expense: expense))
                        .toList(),
                  );
                }

                return Table(
                  columnWidths: const {
                    0: FixedColumnWidth(92),
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(1.6),
                    3: FixedColumnWidth(92),
                  },
                  children: [
                    _row(context, [
                      'Date',
                      'Category',
                      'Note',
                      'Amount',
                    ], isHeader: true),
                    ...expenses.map(
                      (expense) => _row(context, [
                        expense.date,
                        expense.category,
                        expense.note,
                        'Rs. ${expense.amount.toStringAsFixed(0)}',
                      ]),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(
    BuildContext context,
    List<String> cells, {
    bool isHeader = false,
  }) {
    final style = isHeader
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          )
        : Theme.of(context).textTheme.bodyMedium;

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isHeader
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.65),
          ),
        ),
      ),
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(cell, style: style, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  const _ExpenseListTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('${expense.date} - ${expense.note}'),
              ],
            ),
          ),
          Text(
            'Rs. ${expense.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
