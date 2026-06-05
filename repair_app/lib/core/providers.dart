import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/api/api_client.dart';
import 'package:repair_app/core/auth/auth_manager.dart';

// 全局 Provider 声明
// 实际值在 main.dart 中通过 overrideWithValue 注入

final authManagerProvider = Provider<AuthManager>((ref) {
  throw UnimplementedError('Override in main.dart');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Override in main.dart');
});
