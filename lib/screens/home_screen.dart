import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../models/asset.dart';
import '../utils.dart';
import '../services/backup_service.dart';
import '../widgets/asset_icon.dart';
import 'add_asset_screen.dart';
import 'asset_detail_screen.dart';
import 'chart_screen.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ExchangeRateProvider>().load();
      if (mounted) context.read<AssetProvider>().load();
    });
  }

  void _showRateSettings(BuildContext context) {
    final rp = context.read<ExchangeRateProvider>();
    final currencies = ['USD', 'HKD', 'BTC', 'ETH'];
    final ctrls = {for (final c in currencies) c: TextEditingController(text: rp.rates[c]?.toString() ?? '')};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('汇率设置（对 CNY）', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: ctrls[c],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '1 $c = ? CNY',
                labelStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _gold)),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              for (final c in currencies) {
                final v = double.tryParse(ctrls[c]!.text);
                if (v != null && v > 0) await rp.setRate(c, v);
              }
              if (context.mounted) {
                context.read<AssetProvider>().load();
                Navigator.pop(context);
              }
            },
            child: const Text('保存', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      await BackupService.export();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('导入备份', style: TextStyle(color: Colors.white)),
        content: const Text('导入将覆盖所有现有数据，确定继续？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确定', style: TextStyle(color: _gold))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final provider = context.read<AssetProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await BackupService.import();
      if (ok) {
        await provider.load();
        messenger.showSnackBar(const SnackBar(content: Text('导入成功')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('导入取消或文件无效')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Consumer<AssetProvider>(
        builder: (_, p, _) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF0A0A0F),
              title: const Text('资产管家', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, letterSpacing: 2)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart_rounded, color: Colors.white54),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartScreen())),
                ),
                PopupMenuButton<String>(
                  color: _card,
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onSelected: (v) {
                    if (v == 'export') { _export(context); }
                    else if (v == 'import') { _import(context); }
                    else { _showRateSettings(context); }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'rates', child: Row(children: [Icon(Icons.currency_exchange, size: 18, color: Colors.white54), SizedBox(width: 8), Text('汇率设置', style: TextStyle(color: Colors.white))])),
                    const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.upload, size: 18, color: Colors.white54), SizedBox(width: 8), Text('导出备份', style: TextStyle(color: Colors.white))])),
                    const PopupMenuItem(value: 'import', child: Row(children: [Icon(Icons.download, size: 18, color: Colors.white54), SizedBox(width: 8), Text('导入恢复', style: TextStyle(color: Colors.white))])),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(child: _NetWorthHeader(provider: p)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (p.nonLiabilities.isNotEmpty) ...[
                    _sectionLabel('资产账户'),
                    ...p.nonLiabilities.map((a) => _AssetTile(asset: a)),
                  ],
                  if (p.liabilities.isNotEmpty) ...[
                    _sectionLabel('负债'),
                    ...p.liabilities.map((a) => _AssetTile(asset: a)),
                  ],
                  if (p.assets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: Text('暂无资产，点击下方按钮添加', style: TextStyle(color: Colors.white30))),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssetScreen())),
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('添加资产', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 1.5)),
  );
}

class _NetWorthHeader extends StatelessWidget {
  final AssetProvider provider;
  const _NetWorthHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('净资产', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Text(
          formatAmount(provider.netAssets),
          style: const TextStyle(color: _gold, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _MiniStat(label: '总资产', value: formatAmount(provider.totalAssets), color: Colors.white70),
          Container(width: 1, height: 28, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 20)),
          _MiniStat(label: '总负债', value: formatAmount(provider.totalLiabilities), color: Colors.redAccent.shade100),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 1)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
  ]);
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  const _AssetTile({required this.asset});

  @override
  Widget build(BuildContext context) {
    final isLiability = asset.type == AssetType.liability;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: AssetIcon(asset: asset, size: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(asset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(asset.type.label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          Text(
            formatAmount(asset.balance, currency: asset.currency),
            style: TextStyle(
              color: isLiability ? Colors.redAccent.shade100 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ]),
      ),
    );
  }
}

