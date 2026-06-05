import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/models/order.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class HallPage extends ConsumerStatefulWidget {
  const HallPage({super.key});

  @override
  ConsumerState<HallPage> createState() => _HallPageState();
}

class _HallPageState extends ConsumerState<HallPage> {
  List<OrderModel> _orders = [];
  List<dynamic> _categories = [];
  int _selectedCategoryId = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadOrders()]);
  }

  Future<void> _loadCategories() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/categories');
      final cats = resp.data as List<dynamic>;
      // 收集所有叶子类目（有parent_id的二级类目）
      final leaves = <Map<String, dynamic>>[];
      for (final cat in cats) {
        final children = cat['children'] as List<dynamic>?;
        if (children != null) {
          for (final sub in children) {
            leaves.add(sub as Map<String, dynamic>);
          }
        }
      }
      setState(() => _categories = leaves);
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    try {
      // 获取当前位置
      double? lat, lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 5)),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {}

      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{'type': 'hall'};
      if (lat != null && lng != null) {
        params['lat'] = lat.toString();
        params['lng'] = lng.toString();
      }
      if (_selectedCategoryId > 0) {
        params['category_id'] = _selectedCategoryId.toString();
      }
      final resp = await api.get('/orders', params: params);
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
      body: Column(
        children: [
          // 类目筛选
          if (_categories.isNotEmpty)
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildChip('全部', 0),
                  ..._categories.map((cat) {
                    final id = cat['id'] as int;
                    final name = cat['name'] as String;
                    return _buildChip(name, id);
                  }),
                ],
              ),
            ),
          // 订单列表
          Expanded(
            child: _loading
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
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int categoryId) {
    final selected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedCategoryId = categoryId;
            _loading = true;
          });
          _loadOrders();
        },
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
                  if (order.price > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('¥${(order.price / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  Text(order.formattedDistance, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
