class Expense {
  const Expense({
    required this.date,
    required this.category,
    required this.note,
    required this.amount,
  });

  final String date;
  final String category;
  final String note;
  final double amount;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      date: json['date'] as String,
      category: json['category'] as String,
      note: json['note'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'category': category, 'note': note, 'amount': amount};
  }
}
