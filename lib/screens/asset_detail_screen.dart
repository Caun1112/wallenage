import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../providers/asset_provider.dart';
import '../utils.dart';
import '../widgets/asset_icon.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);

class AssetDetailScreen extends StatefulWidget {
  final Asset asset;
  const AssetDetailScreen({super.key, required this.asset});
  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  List<Transaction> _txns = [];
  late Asset _asset;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _loadTxns();
  }

  Future<void> _loadTxns() async {
    final txns = await context.read<AssetProvider>().getTransactions(_asset.id);
    setState(() => _txns = txns);
  }

  void _showUpdateDialog() {
    final ctrl = TextEditingController(text: _asset.balance.toString());
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('更新余额', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(ctrl, '新余额', isNumber: true),
          const SizedBox(height: 12),
          _dialogField(noteCtrl, '备注'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              final v = double.tryParse(ctrl.text);
              if (v == null) return;
              await context.read<AssetProvider>().updateBalance(_asset, v, noteCtrl.text.trim());
              if (mounted) {
                Navigator.pop(context);
                final updated = context.read<AssetProvider>().assets.firstWhere((a) => a.id == _asset.id, orElse: () => _asset);
                setState(() => _asset = updated);
                _loadTxns();
              }
            },
            child: const Text('确认', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, {bool isNumber = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
      ),
    );

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('删除资产', style: TextStyle(color: Colors.white)),
        content: Text('确认删除「${_asset.name}」？此操作不可撤销。', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              await context.read<AssetProvider>().deleteAsset(_asset.id);
              if (mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showUpdateDialog),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _confirmDelete),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _txns.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('暂无变动记录', style: TextStyle(color: Colors.white30))),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _TxnTile(txn: _txns[i], currency: _asset.currency),
                    childCount: _txns.length,
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUpdateDialog,
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        child: const Icon(Icons.sync_alt),
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: BoxDecoration(
      color: _card,
      border: Border(bottom: BorderSide(color: _gold.withValues(alpha: 0.2))),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 60),
      AssetIcon(asset: _asset, size: 48),
      const SizedBox(height: 8),
      Text(_asset.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        formatAmount(_asset.balance, currency: _asset.currency),
        style: const TextStyle(color: _gold, fontSize: 30, fontWeight: FontWeight.bold),
      ),
    ]),
  );
}

class _TxnTile extends StatelessWidget {
  final Transaction txn;
  final String currency;
  const _TxnTile({required this.txn, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPos = txn.amount >= 0;
    final amtColor = isPos ? const Color(0xFF4CAF50) : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: amtColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(isPos ? Icons.arrow_upward : Icons.arrow_downward, color: amtColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txn.note.isEmpty ? '余额变动' : txn.note, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 2),
          Text(formatDate(txn.createdAt), style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isPos ? '+' : ''}${formatAmount(txn.amount, currency: currency)}',
            style: TextStyle(color: amtColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(formatAmount(txn.balanceAfter, currency: currency),
            style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ]),
      ]),
    );
  }
}
