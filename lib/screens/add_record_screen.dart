import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../providers/income_expense_provider.dart';
import '../widgets/asset_icon.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});
  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  String _type = 'expense';
  Asset? _selectedAsset;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    if (_selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择账户')));
      return;
    }
    await context.read<IncomeExpenseProvider>().add(
      type: _type,
      amount: amount,
      category: _selectedAsset!.name,
      assetId: _selectedAsset!.id,
      assetName: _selectedAsset!.name,
      note: _noteCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetProvider>().assets;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('记一笔', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 收入/支出切换
          Container(
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _TypeTab(label: '支出', selected: _type == 'expense', color: Colors.redAccent,
                onTap: () => setState(() => _type = 'expense')),
              _TypeTab(label: '收入', selected: _type == 'income', color: Colors.greenAccent,
                onTap: () => setState(() => _type = 'income')),
            ]),
          ),
          const SizedBox(height: 24),
          // 金额
          _label('金额'),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white12, fontSize: 28),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
            ),
          ),
          const SizedBox(height: 24),
          // 选择账户
          _label('选择账户'),
          const SizedBox(height: 10),
          if (assets.isEmpty)
            const Text('暂无账户，请先添加资产', style: TextStyle(color: Colors.white30))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: assets.map((a) => GestureDetector(
                onTap: () => setState(() => _selectedAsset = a),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedAsset?.id == a.id ? _gold.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedAsset?.id == a.id ? _gold : Colors.white12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: AssetIcon(asset: a, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(a.name, style: TextStyle(
                      color: _selectedAsset?.id == a.id ? _gold : Colors.white54,
                      fontSize: 13,
                    )),
                  ]),
                ),
              )).toList(),
            ),
          const SizedBox(height: 24),
          // 备注
          _label('备注（可选）'),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '添加备注...',
              hintStyle: TextStyle(color: Colors.white12),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1)),
  );
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeTab({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: selected ? color : Colors.white38, fontWeight: FontWeight.bold)),
      ),
    ),
  );
}
