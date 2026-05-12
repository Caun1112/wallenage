import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../db/database.dart';
import 'exchange_rate_provider.dart';

class AssetProvider extends ChangeNotifier {
  List<Asset> _assets = [];
  Map<String, dynamic>? _snapshot;
  final _uuid = const Uuid();
  ExchangeRateProvider? _rateProvider;

  void setRateProvider(ExchangeRateProvider p) {
    _rateProvider = p;
    notifyListeners();
  }

  List<Asset> get assets => _assets;

  List<Asset> get liabilities => _assets.where((a) => a.type == AssetType.liability).toList();
  List<Asset> get nonLiabilities => _assets.where((a) => a.type != AssetType.liability).toList();

  double _toCny(Asset a) => _rateProvider?.toCny(a.balance, a.currency) ?? a.balance;

  double get totalAssets => nonLiabilities.fold(0, (s, a) => s + _toCny(a));
  double get totalLiabilities => liabilities.fold(0, (s, a) => s + _toCny(a));
  double get netAssets => totalAssets - totalLiabilities;

  Map<String, dynamic>? get snapshot => _snapshot;

  double? get netAssetsDelta {
    if (_snapshot == null) return null;
    return netAssets - (_snapshot!['netAssets'] as num).toDouble();
  }

  Map<AssetType, double> get byType {
    final m = <AssetType, double>{};
    for (final a in _assets) {
      m[a.type] = (m[a.type] ?? 0) + a.balance;
    }
    return m;
  }

  Future<void> load() async {
    _assets = await AppDatabase.getAssets();
    _snapshot = await AppDatabase.getSnapshot();
    notifyListeners();
  }

  Future<void> addAsset(String name, AssetType type, double balance, {String currency = 'CNY', String? note}) async {
    final asset = Asset(
      id: _uuid.v4(), name: name, type: type,
      balance: balance, currency: currency, note: note,
      updatedAt: DateTime.now(),
    );
    await AppDatabase.saveAsset(asset);
    if (balance != 0) {
      await AppDatabase.saveTransaction(Transaction(
        id: _uuid.v4(), assetId: asset.id,
        amount: balance, balanceAfter: balance,
        note: '初始余额', createdAt: DateTime.now(),
      ));
    }
    await load();
  }

  Future<void> updateBalance(Asset asset, double newBalance, String note) async {
    final diff = newBalance - asset.balance;
    final updated = asset.copyWith(balance: newBalance);
    await AppDatabase.saveAsset(updated);
    await AppDatabase.saveTransaction(Transaction(
      id: _uuid.v4(), assetId: asset.id,
      amount: diff, balanceAfter: newBalance,
      note: note, createdAt: DateTime.now(),
    ));
    await load();
  }

  Future<void> deleteAsset(String id) async {
    await AppDatabase.deleteAsset(id);
    await load();
  }

  Future<void> lockNetWorth() async {
    _snapshot = {
      'netAssets': netAssets,
      'totalAssets': totalAssets,
      'totalLiabilities': totalLiabilities,
      'lockedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await AppDatabase.saveSnapshot(_snapshot!);
    notifyListeners();
  }

  Future<void> unlockNetWorth() async {
    _snapshot = null;
    await AppDatabase.deleteSnapshot();
    notifyListeners();
  }

  Future<List<Transaction>> getTransactions(String assetId) async =>
      AppDatabase.getTransactions(assetId);
}
