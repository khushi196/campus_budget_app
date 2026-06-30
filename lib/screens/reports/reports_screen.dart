import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/category_budget.dart';
import '../../services/expense_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.expenseService});

  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    final highestCategory = expenseService.categories.reduce(
      (current, next) => current.spent >= next.spent ? current : next,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Report',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'A readable summary of your current spending patterns.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980 ? 3 : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 3.3 : 1.7,
                children: [
                  _ReportMetric(
                    title: 'Total spent',
                    value: _formatCurrency(expenseService.totalSpent),
                    icon: Icons.payments_rounded,
                    color: AppColors.teal,
                  ),
                  _ReportMetric(
                    title: 'Today used',
                    value: _formatCurrency(expenseService.todaySpending),
                    icon: Icons.timelapse_rounded,
                    color: AppColors.coral,
                  ),
                  _ReportMetric(
                    title: 'Highest category',
                    value: highestCategory.name,
                    icon: Icons.trending_up_rounded,
                    color: AppColors.blue,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...expenseService.categories.map(
                    (category) => _ReportCategoryRow(category: category),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCategoryRow extends StatelessWidget {
  const _ReportCategoryRow({required this.category});

  final CategoryBudget category;

  @override
  Widget build(BuildContext context) {
    final color = category.progress > 0.75 ? AppColors.coral : AppColors.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                'Rs. ${category.spent.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: category.progress,
              minHeight: 9,
              color: color,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
