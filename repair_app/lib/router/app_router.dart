import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_app/core/providers.dart';
import 'package:go_router/go_router.dart';

import 'package:repair_app/features/auth/login_page.dart';
import 'package:repair_app/features/auth/register_page.dart';
import 'package:repair_app/features/home/home_page.dart';
import 'package:repair_app/features/order/customer/create_order_page.dart';
import 'package:repair_app/features/order/customer/my_orders_page.dart';
import 'package:repair_app/features/order/customer/order_detail_page.dart';
import 'package:repair_app/features/order/worker/hall_page.dart';
import 'package:repair_app/features/order/worker/my_jobs_page.dart';
import 'package:repair_app/features/chat/chat_page.dart';
import 'package:repair_app/features/chat/conversation_list.dart';
import 'package:repair_app/features/review/review_page.dart';
import 'package:repair_app/features/profile/profile_page.dart';
import 'package:repair_app/features/profile/worker_profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authManagerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.getRole() != null;
      final isAuthRoute = state.matchedLocation == '/login'
          || state.matchedLocation == '/register';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),

      // 订单
      GoRoute(
        path: '/orders/create',
        builder: (_, state) => CreateOrderPage(
          categoryId: state.uri.queryParameters['category_id'],
          categoryName: state.uri.queryParameters['category_name'],
          desc: state.uri.queryParameters['desc'],
        ),
      ),
      GoRoute(path: '/orders/my', builder: (_, __) => const MyOrdersPage()),
      GoRoute(
        path: '/orders/:orderId',
        builder: (_, state) =>
            OrderDetailPage(orderId: int.parse(state.pathParameters['orderId']!)),
      ),
      GoRoute(path: '/orders/hall', builder: (_, __) => const HallPage()),
      GoRoute(
        path: '/orders/hall/:orderId',
        builder: (_, state) =>
            OrderDetailPage(orderId: int.parse(state.pathParameters['orderId']!)),
      ),
      GoRoute(path: '/orders/jobs', builder: (_, __) => const MyJobsPage()),

      // 聊天
      GoRoute(
        path: '/chat',
        builder: (_, state) {
          final orderId = int.tryParse(state.uri.queryParameters['order_id'] ?? '') ?? 0;
          if (orderId == 0) return const ConversationListPage();
          return ChatPage(orderId: orderId);
        },
      ),

      // 评价
      GoRoute(
        path: '/reviews/:userId',
        builder: (_, state) =>
            ReviewPage(userId: int.parse(state.pathParameters['userId']!)),
      ),

      // 个人
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/profile/worker', builder: (_, __) => const WorkerProfilePage()),
    ],
  );
});
