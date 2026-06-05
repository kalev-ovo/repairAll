import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/core/ws/ws_manager.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int orderId;

  const ChatPage({super.key, required this.orderId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  WsManager? _ws;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWs();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/chat/history', params: {'order_id': widget.orderId.toString()});
      final msgs = resp.data as List<dynamic>;
      setState(() {
        _messages.addAll(msgs.cast<Map<String, dynamic>>().map((m) => {
              'type': m['type'],
              'content': m['content'],
              'sender_id': m['sender_id'],
              'created_at': m['created_at'],
            }));
      });
      _scrollToBottom();
    } catch (e) {
      // ignore
    }
  }

  void _connectWs() async {
    final auth = ref.read(authManagerProvider);
    final token = await auth.getToken();
    if (token == null) return;

    _ws = WsManager(onMessage: (msg) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
    _ws!.connect(token: token, orderId: widget.orderId);
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty || _ws == null) return;

    _ws!.send({
      'type': 'text',
      'content': text,
      'order_id': widget.orderId,
    });
    _textController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ws?.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authManagerProvider).getUserId();

    return Scaffold(
      appBar: AppBar(title: const Text('聊天')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender_id'] == userId ||
                    msg['type'] == 'system';

                if (msg['type'] == 'system') {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg['content'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['content'] as String,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          // 输入栏
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
