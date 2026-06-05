import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
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
    super.dispose();
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
      final api = ref.read(apiClientProvider);
      await api.post('/orders', data: {
        'category_id': int.tryParse(widget.categoryId ?? '0') ?? 1,
        'description': desc,
        'address': address,
        'lat': 30.25,
        'lng': 120.16,
        'images': '[]',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
