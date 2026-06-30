class CategoryBudget {
  const CategoryBudget({
    required this.name,
    required this.spent,
    required this.limit,
  });

  final String name;
  final double spent;
  final double limit;

  double get progress => limit == 0 ? 0 : (spent / limit).clamp(0, 1);
  double get remaining => limit - spent;
}
