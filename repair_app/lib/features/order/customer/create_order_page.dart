import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/features/order/customer/location_picker_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? desc;

  const CreateOrderPage({super.key, this.categoryId, this.categoryName, this.desc});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<File> _images = [];
  final List<String> _imageUrls = [];
  double _pickedLat = 0;
  double _pickedLng = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.desc != null) {
      _descController.text = widget.desc!;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      limit: 9,
    );
    if (picked.isNotEmpty) {
      setState(() {
        for (final xfile in picked) {
          if (_images.length < 9) {
            _images.add(File(xfile.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null && mounted) {
      setState(() {
        _addressController.text = result['address'] as String? ?? '';
        _pickedLat = (result['lat'] as num).toDouble();
        _pickedLng = (result['lng'] as num).toDouble();
      });
    }
  }

  Future<void> _uploadImages() async {
    _imageUrls.clear();
    final api = ref.read(apiClientProvider);
    for (final image in _images) {
      final resp = await api.upload('/upload/image', filePath: image.path);
      _imageUrls.add(resp.data['url'] as String);
    }
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    final address = _addressController.text.trim();
    if (desc.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // 先上传图片
      await _uploadImages();

      final api = ref.read(apiClientProvider);
      await api.post('/orders', data: {
        'category_id': int.tryParse(widget.categoryId ?? '0') ?? 1,
        'description': desc,
        'address': address,
        'lat': _pickedLat,
        'lng': _pickedLng,
        'images': _imageUrls.toString(),
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功')),
        );
        context.go('/orders/my');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('发布需求${widget.categoryName != null ? " - ${widget.categoryName}" : ""}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (widget.categoryName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(widget.categoryName!),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '问题描述',
                hintText: '请详细描述您遇到的问题...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '上门地址',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map, size: 18),
              label: Text(_pickedLat != 0 ? '已定位 ✓' : '在地图上选择位置'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '预算价格（元，可选）',
                hintText: '例如：100',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // 图片选择
            const Text('上传图片（可选）', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(entry.key),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_images.length < 9)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 28),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('发布订单'),
            ),
          ],
        ),
      ),
    );
  }
}
