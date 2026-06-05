import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:go_router/go_router.dart';

class WorkerProfilePage extends ConsumerStatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  ConsumerState<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends ConsumerState<WorkerProfilePage> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  bool _loading = false;
  String _verifyStatus = 'none';
  bool _submittingVerify = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/user/profile');
      final worker = (resp.data as Map<String, dynamic>)['worker'] as Map<String, dynamic>?;
      if (worker != null) {
        _nameController.text = worker['real_name'] as String? ?? '';
        _cityController.text = worker['service_city'] as String? ?? '';
        _bioController.text = worker['bio'] as String? ?? '';
        final skills = worker['skills'] as String? ?? '';
        _skillsController.text = skills;
        setState(() {
          _verifyStatus = worker['verify_status'] as String? ?? 'none';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/user/worker-profile', data: {
        'real_name': _nameController.text.trim(),
        'skills': _skillsController.text.trim(),
        'service_city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'years_exp': 0,
        'lat': 0.0,
        'lng': 0.0,
        'service_radius': 10,
        'id_card': '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitVerify() async {
    setState(() => _submittingVerify = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/user/worker/submit-verify');
      setState(() => _verifyStatus = 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('认证申请已提交')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      setState(() => _submittingVerify = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑师傅资料')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 认证状态卡片
            _buildVerifyCard(),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '真实姓名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: '技能标签 (JSON数组)',
                hintText: '["tv_repair","ac_clean"]',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: '服务城市'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '个人简介',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCard() {
    final (Color color, IconData icon, String title, String subtitle) = switch (_verifyStatus) {
      'verified' => (Colors.green, Icons.verified, '已认证', '您的师傅身份已通过审核'),
      'pending' => (Colors.orange, Icons.pending, '审核中', '请耐心等待管理员审核'),
      'rejected' => (Colors.red, Icons.cancel, '未通过', '认证未通过，请修改资料后重新提交'),
      _ => (Colors.grey, Icons.info_outline, '未认证', '提交认证后可接单'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            if (_verifyStatus == 'none' || _verifyStatus == 'rejected')
              ElevatedButton(
                onPressed: _submittingVerify ? null : _submitVerify,
                child: _submittingVerify
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('提交认证'),
              ),
          ],
        ),
      ),
    );
  }
}
