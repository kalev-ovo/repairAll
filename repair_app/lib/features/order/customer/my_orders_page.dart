import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/models/order.dart';
import 'package:go_router/go_router.dart';

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/orders', params: {'type': 'my'});
      setState(() {
        _orders = (resp.data as List).map((e) => OrderModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('暂无订单', style: TextStyle(color: Colors.grey, fontSize: 16))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                    ),
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    switch (order.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'accepted': statusColor = Colors.blue; break;
      case 'ongoing': statusColor = Colors.purple; break;
      case 'completed': statusColor = Colors.green; break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.categoryName ?? '服务', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(order.statusText, style: TextStyle(color: statusColor, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.address, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
