import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/income_expense_provider.dart';
import '../models/income_expense.dart';
import 'add_record_screen.dart';

const _gold = Color(0xFFF5A623);
const _card = Color(0xFF1C1C26);

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<IncomeExpenseProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('收支记录', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      body: Consumer<IncomeExpenseProvider>(
        builder: (_, p, _) {
          if (p.records.isEmpty) {
            return const Center(child: Text('暂无记录', style: TextStyle(color: Colors.white30)));
          }
          return Column(children: [
            _SummaryBar(income: p.totalIncome, expense: p.totalExpense),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: p.records.length,
                itemBuilder: (_, i) => _RecordTile(record: p.records[i]),
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final p = context.read<IncomeExpenseProvider>();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen()))
              .then((_) { if (mounted) p.load(); });
        },
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final double income, expense;
  const _SummaryBar({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Stat(label: '收入', value: '+${income.toStringAsFixed(2)}', color: Colors.greenAccent),
      Container(width: 1, height: 28, color: Colors.white12),
      _Stat(label: '支出', value: '-${expense.toStringAsFixed(2)}', color: Colors.redAccent),
      Container(width: 1, height: 28, color: Colors.white12),
      _Stat(label: '结余', value: (income - expense).toStringAsFixed(2),
        color: income >= expense ? Colors.greenAccent : Colors.redAccent),
    ]),
  );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
  ]);
}

class _RecordTile extends StatelessWidget {
  final IncomeExpense record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.isIncome;
    final color = isIncome ? Colors.greenAccent : Colors.redAccent;
    final sign = isIncome ? '+' : '-';
    final dt = record.createdAt;
    final dateStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => context.read<IncomeExpenseProvider>().delete(record.id),
      child: Container(
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.assetName ?? record.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            if (record.note.isNotEmpty)
              Text(record.note, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$sign${record.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(dateStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
