import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/demo_data.dart';
import '../../models/ai_insight.dart';

class AiAdvisorScreen extends StatelessWidget {
  const AiAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Budget Advisor',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Draft natural-language expense entries and review generated budget insights.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Natural language entry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'I spent 120 on lunch today',
                      suffixIcon: IconButton(
                        tooltip: 'Analyze',
                        onPressed: () {},
                        icon: const Icon(Icons.auto_awesome_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980 ? 3 : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 3.3 : 1.35,
                children: DemoData.insights
                    .map((insight) => _InsightCard(insight: insight))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.level) {
      InsightLevel.positive => AppColors.green,
      InsightLevel.warning => AppColors.coral,
      InsightLevel.neutral => AppColors.blue,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: color),
            const SizedBox(height: 12),
            Text(insight.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(insight.body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
