import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';

class ReviewPage extends ConsumerStatefulWidget {
  final int userId;

  const ReviewPage({super.key, required this.userId});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/reviews/user/${widget.userId}');
      setState(() {
        _reviews = resp.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('评价列表')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('暂无评价', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index] as Map<String, dynamic>;
                    final rating = review['rating'] as int? ?? 5;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                )),
                                const Spacer(),
                                Text(review['created_at'] as String? ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            if (review['content'] != null && review['content'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(review['content'] as String, style: const TextStyle(color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
