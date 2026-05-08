import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/more/about_screen.dart';
import '../screens/more/complaints_screen.dart';
import '../screens/more/customers_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/more/reports_screen.dart';
import '../screens/more/staff_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_edit_screen.dart';
import '../screens/products_screen.dart';
import '../screens/role_denied_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final user = auth.currentUser;
      final loc = state.matchedLocation;
      if (user == null) {
        return loc == '/login' ? null : '/login';
      }
      if (loc == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-denied',
        builder: (_, _) => const RoleDeniedScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) => MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, _) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (_, _) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, _) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (_, _) => const MoreScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/products/new',
        builder: (_, _) => const ProductEditScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, state) =>
            ProductEditScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/more/customers',
        builder: (_, _) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/more/complaints',
        builder: (_, _) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: '/more/staff',
        builder: (_, _) => const StaffScreen(),
      ),
      GoRoute(
        path: '/more/reports',
        builder: (_, _) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/more/about',
        builder: (_, _) => const AboutScreen(),
      ),
    ],
  );
});

User? currentUserOf(WidgetRef ref) =>
    ref.read(firebaseAuthProvider).currentUser;
