import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  LatLng? _center;
  String _address = '获取地址中...';
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 5),
      );
      _center = LatLng(position.latitude, position.longitude);
    } catch (_) {
      _center = LatLng(
        widget.initialLat ?? 30.25,
        widget.initialLng ?? 120.16,
      );
    }
    _mapController.move(_center!, 15);
    setState(() => _locating = false);
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    if (_center == null) return;
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${_center!.latitude}&lon=${_center!.longitude}&zoom=18&accept-language=zh';
      final resp = await Dio().get(url, options: Options(headers: {'User-Agent': 'RepairApp/1.0'}));
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        setState(() {
          _address = data['display_name'] as String? ?? '未知地址';
        });
      }
    } catch (_) {
      setState(() => _address = '${_center!.latitude.toStringAsFixed(6)}, ${_center!.longitude.toStringAsFixed(6)}');
    }
  }

  void _confirm() {
    if (_center == null) return;
    Navigator.of(context).pop({
      'lat': _center!.latitude,
      'lng': _center!.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择位置')),
      body: _locating
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center!,
                    initialZoom: 15.0,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _center = event.camera.center;
                        _reverseGeocode();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.repair_app',
                    ),
                  ],
                ),
                // 中心十字准星
                const Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
                // 底部确认栏
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_address, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirm,
                              child: const Text('确认此位置'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
