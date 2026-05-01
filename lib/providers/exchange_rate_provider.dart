import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../db/database.dart';

const _defaults = {'USD': 7.24, 'HKD': 0.93, 'BTC': 680000.0, 'ETH': 25000.0, 'CNY': 1.0};

class ExchangeRateProvider extends ChangeNotifier {
  Map<String, double> _rates = Map.of(_defaults);

  Map<String, double> get rates => _rates;

  double toCny(double amount, String currency) => amount * (_rates[currency] ?? 1.0);

  Future<void> load() async {
    final raw = await AppDatabase.getSetting('exchange_rates');
    if (raw != null) {
      final saved = Map<String, dynamic>.from(jsonDecode(raw));
      _rates = {..._defaults, ...saved.map((k, v) => MapEntry(k, (v as num).toDouble()))};
    }
    notifyListeners();
  }

  Future<void> setRate(String currency, double rate) async {
    _rates[currency] = rate;
    await AppDatabase.setSetting('exchange_rates', jsonEncode(_rates));
    notifyListeners();
  }
}
