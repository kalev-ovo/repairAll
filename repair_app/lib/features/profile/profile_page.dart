import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/user/profile');
      setState(() {
        _profile = resp.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchRole() async {
    final auth = ref.read(authManagerProvider);
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.post('/user/switch-role');
      await auth.saveAuth(
        token: resp.data['token'],
        role: resp.data['role'],
        userId: auth.getUserId()!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换为${resp.data['role'] == 'worker' ? '师傅' : '用户'}')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final auth = ref.read(authManagerProvider);
    await auth.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authManagerProvider).getRole();
    final user = _profile?['user'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 用户头像和名称
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            (user?['name'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user?['name'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(role == 'worker' ? '师傅' : '用户', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 功能列表
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(role == 'worker' ? '切换为用户端' : '切换为师傅端'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _switchRole,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: const Text('我的评价'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/reviews/${user?['id'] ?? 0}'),
                      ),
                      if (role == 'worker') ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('编辑师傅资料'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/profile/worker'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('退出登录'),
                ),
              ],
            ),
    );
  }
}
