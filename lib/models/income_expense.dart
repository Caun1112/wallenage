class IncomeExpense {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String? assetId;
  final String? assetName;
  final String note;
  final DateTime createdAt;

  const IncomeExpense({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.assetId,
    this.assetName,
    required this.note,
    required this.createdAt,
  });

  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'amount': amount,
    'category': category,
    'assetId': assetId,
    'assetName': assetName,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory IncomeExpense.fromMap(Map<String, dynamic> m) => IncomeExpense(
    id: m['id'],
    type: m['type'],
    amount: m['amount'],
    category: m['category'] ?? '',
    assetId: m['assetId'] as String?,
    assetName: m['assetName'] as String?,
    note: m['note'] ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );
}
