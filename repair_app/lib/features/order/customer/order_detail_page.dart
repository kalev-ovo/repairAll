import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/models/order.dart';
import 'package:go_router/go_router.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  OrderModel? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/orders/${widget.orderId}');
      setState(() {
        _order = OrderModel.fromJson(resp.data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _doAction(String action) async {
    final api = ref.read(apiClientProvider);
    try {
      if (action == 'cancel') {
        await api.put('/orders/${widget.orderId}/cancel', data: {'reason': '用户取消'});
      } else if (action == 'complete') {
        await api.put('/orders/${widget.orderId}/complete');
      } else if (action == 'chat') {
        context.go('/chat?order_id=${widget.orderId}');
        return;
      }
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.read(authManagerProvider).getRole();

    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('订单不存在'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 12),
                      _buildInfoCard(),
                      const SizedBox(height: 12),
                      _buildDescCard(),
                      const SizedBox(height: 24),
                      // 操作按钮
                      if (_order!.status == 'pending' && role == 'worker')
                        ElevatedButton(onPressed: () => _doAction('accept'),
                            child: const Text('接单'))
                      else if (_order!.status == 'accepted' && role == 'worker')
                        ElevatedButton(onPressed: () => _doAction('arrive'),
                            child: const Text('确认到达'))
                      else if (_order!.status == 'ongoing')
                        ElevatedButton(onPressed: () => _doAction('complete'),
                            child: const Text('确认完成')),
                      const SizedBox(height: 8),
                      if (_order!.canCancel)
                        OutlinedButton(
                          onPressed: () => _doAction('cancel'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('取消订单'),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _doAction('chat'),
                        icon: const Icon(Icons.chat),
                        label: const Text('联系对方'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(_getStatusIcon(), size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(_order!.statusText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('订单号: ${_order!.orderNo}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.category, '服务类别', _order!.categoryName ?? '-'),
            if (_order!.price > 0) ...[
              const Divider(),
              _infoRow(Icons.monetization_on, '预算价格', '¥${(_order!.price / 100).toStringAsFixed(2)}'),
            ],
            const Divider(),
            _infoRow(Icons.location_on, '地址', _order!.address),
            if (_order!.workerName != null) ...[
              const Divider(),
              _infoRow(Icons.person, '师傅', _order!.workerName!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('问题描述', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_order!.description, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_order!.status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.thumb_up;
      case 'ongoing': return Icons.build;
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }
}
