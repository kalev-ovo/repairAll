import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/categories');
      setState(() {
        _categories = resp.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authManagerProvider).getRole();
    final isWorker = role == 'worker';

    return Scaffold(
      appBar: AppBar(
        title: Text(isWorker ? '师傅端' : '家政维修'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.go('/chat'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 搜索栏
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: '搜索服务...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  context.go('/orders/create?desc=$value');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 快捷操作（按角色）
                  _buildQuickActions(isWorker),
                  const SizedBox(height: 16),
                  // 服务类目
                  const Text('服务分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._categories.map(_buildCategoryCard),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(isWorker),
    );
  }

  Widget _buildQuickActions(bool isWorker) {
    return Row(
      children: [
        if (!isWorker) ...[
          Expanded(
            child: _ActionCard(
              icon: Icons.add_circle_outline,
              label: '发布需求',
              color: Colors.blue,
              onTap: () => context.go('/orders/create'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _ActionCard(
            icon: isWorker ? Icons.work_outline : Icons.receipt_long,
            label: isWorker ? '接单大厅' : '我的订单',
            color: Colors.green,
            onTap: () => context.go(isWorker ? '/orders/hall' : '/orders/my'),
          ),
        ),
        if (isWorker) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.bar_chart,
              label: '收入统计',
              color: Colors.orange,
              onTap: () => context.go('/income-stats'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryCard(dynamic cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(_getCategoryIcon(cat['icon'] as String?),
            color: Theme.of(context).colorScheme.primary),
        title: Text(cat['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
        children: (cat['children'] as List<dynamic>?)?.map<Widget>((sub) {
              return ListTile(
                title: Text(sub['name'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.go('/orders/create?category_id=${sub['id']}&category_name=${sub['name']}');
                },
              );
            }).toList() ??
            [],
      ),
    );
  }

  Widget _buildBottomNav(bool isWorker) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
        if (isWorker)
          const BottomNavigationBarItem(icon: Icon(Icons.work), label: '接单')
        else
          const BottomNavigationBarItem(icon: Icon(Icons.receipt), label: '订单'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.go(isWorker ? '/orders/hall' : '/orders/my');
            break;
          case 2:
            context.go('/profile');
            break;
        }
      },
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'tv': return Icons.tv;
      case 'kitchen': return Icons.kitchen;
      case 'air': return Icons.air;
      case 'plumbing': return Icons.plumbing;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'home_repair_service': return Icons.home_repair_service;
      case 'build': return Icons.build;
      case 'water_drop': return Icons.water_drop;
      case 'electric_bolt': return Icons.electric_bolt;
      default: return Icons.handyman;
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
