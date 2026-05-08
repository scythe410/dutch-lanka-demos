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
    return ProviderScope(
      child: _RouterApp(environment: environment),
    );
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
    // FCM service can run without a router; we hand it the GoRouter once
    // it's available (set in build, since the provider is read there).
    Future.microtask(() async {
      final svc = ref.read(fcmServiceProvider);
      await svc.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Tap-to-route — `data.type == 'order_status'` opens the tracking
    // screen. Keep this map terse; new types just add a switch case.
    ref.read(fcmServiceProvider).setRouter((data) {
      final type = data['type'] as String?;
      switch (type) {
        case 'order_status':
          final orderId = data['orderId'] as String?;
          if (orderId != null) router.go('/order/$orderId');
          break;
        default:
          // Unknown payload — drop.
          break;
      }
    });
    return MaterialApp.router(
      title: 'Dutch Lanka',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
