import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/category_budget.dart';
import '../../services/expense_service.dart';
import '../../widgets/money_dialogs.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
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
          Text(
            'Category Budgets',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'See how each spending category is tracking against its limit.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920 ? 2 : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 3.4 : 2.3,
                children: expenseService.categories
                    .map(
                      (category) => _CategoryCard(
                        category: category,
                        onEditLimit: () => _editLimit(context, category),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editLimit(BuildContext context, CategoryBudget category) async {
    final limit = await showDialog<double>(
      context: context,
      builder: (context) => EditLimitDialog(
        title: 'Set ${category.name} limit',
        initialLimit: category.limit,
      ),
    );

    if (limit == null) {
      return;
    }

    expenseService.setCategoryLimit(category.name, limit);
    onDataChanged();
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onEditLimit});

  final CategoryBudget category;
  final VoidCallback onEditLimit;

  @override
  Widget build(BuildContext context) {
    final color = category.progress > 0.75 ? AppColors.coral : AppColors.teal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.category_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${(category.progress * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(width: 6),
                IconButton(
                  key: Key('edit-limit-${category.name}'),
                  tooltip: 'Edit limit',
                  onPressed: onEditLimit,
                  icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: category.progress,
                minHeight: 10,
                color: color,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rs. ${category.spent.toStringAsFixed(0)} used, Rs. ${category.remaining.toStringAsFixed(0)} left',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
