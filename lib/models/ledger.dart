class Ledger {
  const Ledger({required this.friendName, required this.amount});

  final String friendName;
  final double amount;

  bool get theyOweYou => amount >= 0;

  factory Ledger.fromJson(Map<String, dynamic> json) {
    return Ledger(
      friendName: json['friendName'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'friendName': friendName, 'amount': amount};
  }
}
