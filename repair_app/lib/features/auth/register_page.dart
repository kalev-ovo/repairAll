import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String _role = 'customer';
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/auth/send-code', data: {'phone': phone});
      setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.post('/auth/register', data: {
        'phone': phone,
        'code': code,
        'role': _role,
      });
      final data = resp.data as Map<String, dynamic>;
      final auth = ref.read(authManagerProvider);
      await auth.saveAuth(
        token: data['token'],
        role: data['user']['role'],
        userId: data['user']['id'],
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册失败: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 角色选择
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.person,
                      title: '我是用户',
                      subtitle: '寻找维修服务',
                      selected: _role == 'customer',
                      onTap: () => setState(() => _role = 'customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.build,
                      title: '我是师傅',
                      subtitle: '提供维修服务',
                      selected: _role == 'worker',
                      onTap: () => setState(() => _role = 'worker'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),
              if (_codeSent) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('注册'),
                ),
              ],
              if (!_codeSent) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  child: const Text('获取验证码'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('已有账号？去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Theme.of(context).colorScheme.primary : null)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
