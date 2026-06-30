class AiInsight {
  const AiInsight({
    required this.title,
    required this.body,
    required this.level,
  });

  final String title;
  final String body;
  final InsightLevel level;
}

enum InsightLevel { positive, warning, neutral }
