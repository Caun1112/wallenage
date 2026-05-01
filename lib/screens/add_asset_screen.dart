import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});
  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  AssetType _type = AssetType.cash;
  String _currency = 'CNY';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text) ?? 0;
    if (name.isEmpty) return;
    await context.read<AssetProvider>().addAsset(
      name, _type, balance, currency: _currency, note: _noteCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: const Text('添加资产', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('资产类型', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildTypeGrid(),
          const SizedBox(height: 24),
          _buildField('账户名称', _nameCtrl, hint: '例：招商银行储蓄卡'),
          const SizedBox(height: 16),
          _buildCurrencyAndBalance(),
          const SizedBox(height: 16),
          _buildField('备注（可选）', _noteCtrl),
        ],
      ),
    );
  }

  Widget _buildTypeGrid() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: AssetType.values.map((t) {
      final sel = t == _type;
      return GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? _gold.withValues(alpha: 0.15) : _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _gold : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(t.label,
            style: TextStyle(color: sel ? _gold : Colors.white54, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      );
    }).toList(),
  );

  Widget _buildCurrencyAndBalance() => Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currency,
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: ['CNY', 'USD', 'HKD', 'BTC', 'ETH']
              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _currency = v!),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(child: _buildField('当前余额', _balanceCtrl, hint: '0.00', isNumber: true)),
  ]);

  Widget _buildField(String label, TextEditingController ctrl, {String hint = '', bool isNumber = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _gold)),
      ),
    );
}
