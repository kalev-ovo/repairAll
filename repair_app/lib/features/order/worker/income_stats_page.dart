import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';

class IncomeStatsPage extends ConsumerStatefulWidget {
  const IncomeStatsPage({super.key});

  @override
  ConsumerState<IncomeStatsPage> createState() => _IncomeStatsPageState();
}

class _IncomeStatsPageState extends ConsumerState<IncomeStatsPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/user/worker-stats');
      setState(() {
        _stats = resp.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收入统计')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('加载失败'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 收入总览
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      // 本月统计
                      _buildMonthCard(),
                      const SizedBox(height: 16),
                      // 订单状态概览
                      _buildStatusCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final totalEarnings = (_stats!['total_earnings'] as num).toDouble() / 100;
    final totalOrders = _stats!['total_orders'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('累计收入', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '¥${totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Text('累计完成 $totalOrders 单', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard() {
    final monthEarnings = (_stats!['month_earnings'] as num).toDouble() / 100;
    final monthOrders = _stats!['month_orders'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('本月收入', '¥${monthEarnings.toStringAsFixed(2)}', Colors.green),
            ),
            const Divider(height: 40),
            Expanded(
              child: _buildStatItem('本月订单', '$monthOrders 单', Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final pendingOrders = _stats!['pending_orders'] as int;
    final ongoingOrders = _stats!['ongoing_orders'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('订单状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    '待接单', '$pendingOrders', Colors.blue.withValues(alpha: 0.1), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusItem(
                    '进行中', '$ongoingOrders', Colors.orange.withValues(alpha: 0.1), Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: textColor)),
        ],
      ),
    );
  }
}
