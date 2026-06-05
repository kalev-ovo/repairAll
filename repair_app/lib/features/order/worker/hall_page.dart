import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/models/order.dart';
import 'package:go_router/go_router.dart';

class HallPage extends ConsumerStatefulWidget {
  const HallPage({super.key});

  @override
  ConsumerState<HallPage> createState() => _HallPageState();
}

class _HallPageState extends ConsumerState<HallPage> {
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
      final resp = await api.get('/orders', params: {'type': 'hall'});
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
      appBar: AppBar(title: const Text('接单大厅')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('暂无可接订单', style: TextStyle(color: Colors.grey, fontSize: 16))),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/orders/hall/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(order.categoryName ?? '服务', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.address, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                  const Text('5km', style: TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
