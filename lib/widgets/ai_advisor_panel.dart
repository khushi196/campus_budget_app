import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/ai_insight.dart';

class AiAdvisorPanel extends StatelessWidget {
  const AiAdvisorPanel({super.key, required this.insights});

  final List<AiInsight> insights;

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.violet, AppColors.coral],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Budget Advisor',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'I spent 120 on lunch today',
                suffixIcon: IconButton(
                  tooltip: 'Analyze expense',
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _InsightTile(insight: insight)),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.level) {
      InsightLevel.positive => AppColors.green,
      InsightLevel.warning => AppColors.coral,
      InsightLevel.neutral => AppColors.blue,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(insight.body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
