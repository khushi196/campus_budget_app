import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/ai_insight.dart';

class AiAdvisorPanel extends StatefulWidget {
  const AiAdvisorPanel({
    super.key,
    required this.insights,
    required this.onOpenAdvisor,
  });

  final List<AiInsight> insights;
  final VoidCallback onOpenAdvisor;

  @override
  State<AiAdvisorPanel> createState() => _AiAdvisorPanelState();
}

class _AiAdvisorPanelState extends State<AiAdvisorPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'I spent 120 on lunch today',
                suffixIcon: IconButton(
                  tooltip: 'Open AI Advisor',
                  onPressed: widget.onOpenAdvisor,
                  icon: const Icon(Icons.auto_awesome_rounded),
                ),
              ),
              onSubmitted: (_) => widget.onOpenAdvisor(),
            ),
            const SizedBox(height: 16),
            ...widget.insights.map((insight) => _InsightTile(insight: insight)),
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
