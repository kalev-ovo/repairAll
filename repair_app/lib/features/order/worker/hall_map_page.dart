import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/models/order.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class HallMapPage extends ConsumerStatefulWidget {
  const HallMapPage({super.key});

  @override
  ConsumerState<HallMapPage> createState() => _HallMapPageState();
}

class _HallMapPageState extends ConsumerState<HallMapPage> {
  List<OrderModel> _orders = [];
  LatLng? _myLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    double? lat, lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 5),
      );
      lat = position.latitude;
      lng = position.longitude;
      _myLocation = LatLng(lat!, lng!);
    } catch (_) {
      // 默认杭州
      _myLocation = const LatLng(30.25, 120.16);
      lat = 30.25;
      lng = 120.16;
    }

    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/orders', params: {
        'type': 'hall',
        'lat': lat.toString(),
        'lng': lng.toString(),
      });
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
      appBar: AppBar(title: const Text('附近订单')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _myLocation ?? const LatLng(30.25, 120.16),
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.repair_app',
                    ),
                    // 当前位置
                    if (_myLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                          ),
                        ],
                      ),
                    // 订单标记
                    MarkerLayer(
                      markers: _orders.where((o) => o.lat != 0 && o.lng != 0).map((order) {
                        return Marker(
                          point: LatLng(order.lat, order.lng),
                          width: 200,
                          height: 70,
                          child: GestureDetector(
                            onTap: () => _showOrderSheet(order),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.build, size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          order.categoryName ?? '维修',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (order.price > 0) ...[
                                        const SizedBox(width: 4),
                                        Text('¥${(order.price / 100).toInt()}',
                                            style: const TextStyle(fontSize: 11, color: Colors.orange)),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.location_on, color: Colors.red, size: 24),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // 返回列表按钮
                Positioned(
                  top: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'back_to_list',
                    onPressed: () => context.pop(),
                    child: const Icon(Icons.list),
                  ),
                ),
                // 重新定位按钮
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'relocate',
                    onPressed: () => _loadData(),
                    child: const Icon(Icons.gps_fixed),
                  ),
                ),
              ],
            ),
    );
  }

  void _showOrderSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.categoryName ?? '服务', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(order.description, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.address, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  if (order.price > 0)
                    Text('¥${(order.price / 100).toInt()}', style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/orders/hall/${order.id}');
                  },
                  child: const Text('查看详情'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
