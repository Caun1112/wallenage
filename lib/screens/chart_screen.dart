import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/asset_provider.dart';
import '../models/asset.dart';
import '../utils.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);
const _typeColors = [
  Color(0xFFF5A623), Color(0xFF43C6AC), Color(0xFF7B61FF),
  Color(0xFFFF6B6B), Color(0xFF4ECDC4),
];

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: const Text('图表分析', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AssetProvider>(
        builder: (_, p, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryRow(provider: p),
            const SizedBox(height: 16),
            _PieChartCard(provider: p),
            const SizedBox(height: 16),
            _BarChartCard(provider: p),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AssetProvider provider;
  const _SummaryRow({required this.provider});

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatCard(label: '总资产', value: formatAmount(provider.totalAssets), color: _gold),
    const SizedBox(width: 8),
    _StatCard(label: '总负债', value: formatAmount(provider.totalLiabilities), color: Colors.redAccent),
    const SizedBox(width: 8),
    _StatCard(label: '净资产', value: formatAmount(provider.netAssets), color: const Color(0xFF43C6AC)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );
}

class _PieChartCard extends StatelessWidget {
  final AssetProvider provider;
  const _PieChartCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final byType = provider.byType;
    if (byType.isEmpty) return const SizedBox.shrink();
    final total = byType.values.fold(0.0, (s, v) => s + v.abs());
    final entries = byType.entries.toList();
    final sections = entries.asMap().entries.map((e) {
      final pct = total == 0 ? 0.0 : e.value.value.abs() / total * 100;
      return PieChartSectionData(
        value: e.value.value.abs(),
        color: _typeColors[e.key % _typeColors.length],
        title: '${pct.toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('资产分布', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Row(children: [
            Expanded(child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30))),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: _typeColors[e.key % _typeColors.length], shape: BoxShape.circle,
                  )),
                  const SizedBox(width: 6),
                  Text(e.value.key.label,
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              )).toList(),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final AssetProvider provider;
  const _BarChartCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final byType = provider.byType;
    if (byType.isEmpty) return const SizedBox.shrink();
    final entries = byType.entries.toList();
    final maxVal = entries.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('各类资产对比', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxVal * 1.2,
            barGroups: entries.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(
                toY: e.value.value.abs(),
                color: _typeColors[e.key % _typeColors.length],
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )],
            )).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  return Text(entries[i].key.label, style: const TextStyle(fontSize: 11, color: Colors.white54));
                },
              )),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          )),
        ),
      ]),
    );
  }
}
