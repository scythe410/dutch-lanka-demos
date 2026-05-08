import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(lowStockAlertsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Low', orange: 'stock'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: alertsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Center(
            child: Text(
              "We couldn't load alerts.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.check, size: 56, color: AppColors.primary),
                    const SizedBox(height: Space.lg),
                    Text(
                      'All stocks are healthy.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) => _AlertRow(alert: alerts[i]),
          );
        },
      ),
    );
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({required this.alert});
  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productName = (alert['productName'] as String?) ??
        (alert['productId'] as String?) ??
        'Product';
    final stock = (alert['stock'] as int?) ?? 0;
    final threshold = (alert['threshold'] as int?) ?? 0;
    final createdAt = alert['createdAt'];
    final created = createdAt is Timestamp
        ? DateFormat('d MMM, h:mm a').format(createdAt.toDate())
        : '—';
    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            const IconTile(icon: LucideIcons.triangle_alert),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock $stock · threshold $threshold · $created',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(acknowledgeAlertProvider)(alert['id'] as String),
              child: const Text(
                'Mark resolved',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
