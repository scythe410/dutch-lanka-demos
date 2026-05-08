import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/router.dart';
import 'services/fcm_service.dart';

enum AppEnvironment { dev, prod }

class App extends StatelessWidget {
  const App({super.key, required this.environment});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: _RouterApp(environment: environment));
  }
}

class _RouterApp extends ConsumerStatefulWidget {
  const _RouterApp({required this.environment});
  final AppEnvironment environment;

  @override
  ConsumerState<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends ConsumerState<_RouterApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(fcmServiceProvider).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.read(fcmServiceProvider).setRouter((data) {
      final type = data['type'] as String?;
      final orderId = data['orderId'] as String?;
      switch (type) {
        case 'new_order':
        case 'order_status':
          if (orderId != null) router.go('/orders/$orderId');
          break;
        case 'low_stock':
          router.go('/inventory');
          break;
        case 'complaint':
          router.go('/more/complaints');
          break;
      }
    });
    return MaterialApp.router(
      title: 'Dutch Lanka Manager',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
