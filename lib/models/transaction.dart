class Transaction {
  final String id;
  final String assetId;
  final double amount;
  final double balanceAfter;
  final String note;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.assetId,
    required this.amount,
    required this.balanceAfter,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'assetId': assetId,
    'amount': amount,
    'balanceAfter': balanceAfter,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id: m['id'],
    assetId: m['assetId'],
    amount: m['amount'],
    balanceAfter: m['balanceAfter'],
    note: m['note'] ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );
}
