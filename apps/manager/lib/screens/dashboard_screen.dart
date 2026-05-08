import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaysSalesCentsProvider);
    final ordersAsync = ref.watch(incomingOrdersProvider);
    final alertsAsync = ref.watch(lowStockAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const TwoToneTitle(black: 'Dutch', orange: 'Lanka'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(LucideIcons.log_out, color: AppColors.primary),
            onPressed: () async {
              await ref.read(firebaseAuthProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: "Today's sales",
                  value: salesAsync.when(
                    data: (cents) =>
                        'LKR ${(cents / 100).toStringAsFixed(0)}',
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: KpiTile(
                  label: 'Active orders',
                  value: ordersAsync.when(
                    data: (l) => l.length.toString(),
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  onTap: () => context.go('/orders'),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: KpiTile(
                  label: 'Low stock',
                  value: alertsAsync.when(
                    data: (l) => l.length.toString(),
                    loading: () => '…',
                    error: (_, _) => '—',
                  ),
                  onTap: () => context.go('/inventory'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Text(
            'Incoming orders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.md),
          ordersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text(
                "We couldn't load orders.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xl),
                  child: Center(
                    child: Text(
                      'No active orders right now.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final o in orders) ...[
                    OrderRow(
                      order: o,
                      onTap: () => context.push('/orders/${o['id']}'),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
