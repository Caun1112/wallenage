import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/income_expense.dart';
import '../db/database.dart';
import 'asset_provider.dart';

class IncomeExpenseProvider extends ChangeNotifier {
  List<IncomeExpense> _records = [];
  AssetProvider? _assetProvider;

  List<IncomeExpense> get records => _records;

  double get totalIncome => _records.where((r) => r.isIncome).fold(0, (s, r) => s + r.amount);
  double get totalExpense => _records.where((r) => !r.isIncome).fold(0, (s, r) => s + r.amount);

  void setAssetProvider(AssetProvider? p) {
    _assetProvider = p;
  }

  Future<void> load() async {
    final rows = await AppDatabase.getIncomeExpenses();
    _records = rows.map(IncomeExpense.fromMap).toList();
    notifyListeners();
  }

  Future<void> add({
    required String type,
    required double amount,
    required String category,
    String? assetId,
    String? assetName,
    required String note,
  }) async {
    final r = IncomeExpense(
      id: const Uuid().v4(),
      type: type,
      amount: amount,
      category: category,
      assetId: assetId,
      assetName: assetName,
      note: note,
      createdAt: DateTime.now(),
    );
    await AppDatabase.saveIncomeExpense(r.toMap());
    _records.insert(0, r);

    if (assetId != null && _assetProvider != null) {
      final asset = _assetProvider!.assets.where((a) => a.id == assetId).firstOrNull;
      if (asset != null) {
        final newBalance = r.isIncome ? asset.balance + amount : asset.balance - amount;
        await _assetProvider!.updateBalance(asset, newBalance, '${r.isIncome ? "收入" : "支出"} $assetName $amount');
      }
    }

    notifyListeners();
  }

  Future<void> delete(String id) async {
    final record = _records.where((r) => r.id == id).firstOrNull;
    if (record == null) return;

    await AppDatabase.deleteIncomeExpense(id);
    _records.removeWhere((r) => r.id == id);

    if (record.assetId != null && _assetProvider != null) {
      final asset = _assetProvider!.assets.where((a) => a.id == record.assetId).firstOrNull;
      if (asset != null) {
        final newBalance = record.isIncome ? asset.balance - record.amount : asset.balance + record.amount;
        await _assetProvider!.updateBalance(asset, newBalance, '删除${record.isIncome ? "收入" : "支出"} ${record.assetName} ${record.amount}');
      }
    }

    notifyListeners();
  }
}
