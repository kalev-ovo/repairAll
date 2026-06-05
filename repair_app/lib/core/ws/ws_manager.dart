import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsManager {
  static const String _wsUrl = 'ws://134.175.109.101:8080/api/v1/ws/chat';
  // Android 模拟器用 10.0.2.2，真机改为服务器地址

  WebSocketChannel? _channel;
  final void Function(Map<String, dynamic>) onMessage;

  WsManager({required this.onMessage});

  void connect({required String token, required int orderId}) {
    _channel = WebSocketChannel.connect(
      Uri.parse('$_wsUrl?token=$token&order_id=$orderId'),
    );

    _channel!.stream.listen(
      (data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        onMessage(msg);
      },
      onError: (error) {
        // ignore: avoid_print
        print('WS error: $error');
      },
      onDone: () {
        // ignore: avoid_print
        print('WS closed');
      },
    );
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
