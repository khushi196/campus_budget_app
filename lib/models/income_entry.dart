class IncomeEntry {
  const IncomeEntry({
    required this.date,
    required this.source,
    required this.amount,
  });

  final String date;
  final String source;
  final double amount;

  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    return IncomeEntry(
      date: json['date'] as String,
      source: json['source'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'source': source, 'amount': amount};
  }
}
