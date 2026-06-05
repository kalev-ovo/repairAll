import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/api/api_client.dart';
import 'package:repair_app/core/auth/auth_manager.dart';
import 'package:repair_app/core/providers.dart';
import 'package:repair_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authManager = AuthManager();
  await authManager.init();

  final apiClient = ApiClient(authManager: authManager);

  runApp(
    ProviderScope(
      overrides: [
        authManagerProvider.overrideWithValue(authManager),
        apiClientProvider.overrideWithValue(apiClient),
      ],
      child: const RepairApp(),
    ),
  );
}
