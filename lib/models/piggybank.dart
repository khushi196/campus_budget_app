class Piggybank {
  const Piggybank({
    required this.name,
    required this.goalAmount,
    required this.savedAmount,
    required this.dueDate,
  });

  final String name;
  final double goalAmount;
  final double savedAmount;
  final String dueDate;

  double get progress =>
      goalAmount == 0 ? 0 : (savedAmount / goalAmount).clamp(0, 1);

  factory Piggybank.fromJson(Map<String, dynamic> json) {
    return Piggybank(
      name: json['name'] as String,
      goalAmount: (json['goalAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
      dueDate: json['dueDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'goalAmount': goalAmount,
      'savedAmount': savedAmount,
      'dueDate': dueDate,
    };
  }
}
