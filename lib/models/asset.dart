enum AssetType {
  cash,       // 银行/现金
  investment, // 投资
  crypto,     // 加密货币
  fixed,      // 固定资产
  liability,  // 负债
}

extension AssetTypeExt on AssetType {
  String get label => const {
    AssetType.cash: '银行/现金',
    AssetType.investment: '投资',
    AssetType.crypto: '加密货币',
    AssetType.fixed: '固定资产',
    AssetType.liability: '负债',
  }[this]!;

  String get fallbackIcon => const {
    AssetType.cash: '🏦',
    AssetType.investment: '📈',
    AssetType.crypto: '₿',
    AssetType.fixed: '🏠',
    AssetType.liability: '💳',
  }[this]!;
}

class Asset {
  final String id;
  final String name;
  final AssetType type;
  final double balance;
  final String currency;
  final String? note;
  final DateTime updatedAt;

  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'CNY',
    this.note,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.index,
    'balance': balance,
    'currency': currency,
    'note': note,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Asset.fromMap(Map<String, dynamic> m) => Asset(
    id: m['id'],
    name: m['name'],
    type: AssetType.values[m['type']],
    balance: m['balance'],
    currency: m['currency'] ?? 'CNY',
    note: m['note'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt']),
  );

  Asset copyWith({String? name, double? balance, String? note}) => Asset(
    id: id,
    name: name ?? this.name,
    type: type,
    balance: balance ?? this.balance,
    currency: currency,
    note: note ?? this.note,
    updatedAt: DateTime.now(),
  );
}
