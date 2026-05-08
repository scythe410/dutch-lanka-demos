import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';

const _statusLabels = {
  'pending_payment': 'Awaiting payment',
  'paid': 'Paid',
  'preparing': 'Preparing',
  'dispatched': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

/// Read-only summary of a finished order. The tracking screen handles
/// in-progress states; this one is opened from `OrderHistoryScreen` for
/// `delivered` / `cancelled` rows.
class OrderSummaryScreen extends ConsumerWidget {
  const OrderSummaryScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Order', orange: 'summary'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.go('/orders'),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load this order.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text(
                'Order not found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return _Body(orderId: orderId, order: order);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.orderId, required this.order});
  final String orderId;
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String?) ?? 'pending_payment';
    final totalCents = (order['totalCents'] as int?) ?? 0;
    final subtotalCents = (order['subtotalCents'] as int?) ?? 0;
    final deliveryFeeCents = (order['deliveryFeeCents'] as int?) ?? 0;
    final paymentMethod = (order['paymentMethod'] as String?) ?? '—';
    final createdAt = order['createdAt'];
    final deliveredAt = order['deliveredAt'];
    final items = (order['items'] as List?) ?? const [];

    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${orderId.substring(0, orderId.length.clamp(0, 6))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Space.xs),
              Text(
                _formatTs(createdAt) ?? 'Placed —',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: Space.md),
              Text(
                _statusLabels[status] ?? status,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.primary),
              ),
              if (deliveredAt is Timestamp) ...[
                const SizedBox(height: Space.xs),
                Text(
                  'Delivered ${_formatTs(deliveredAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        if (items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Space.md),
                for (final raw in items)
                  if (raw is Map) _ItemRow(item: Map<String, dynamic>.from(raw)),
              ],
            ),
          ),
        const SizedBox(height: Space.lg),
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              _Line(label: 'Subtotal', value: subtotalCents),
              const SizedBox(height: Space.xs),
              _Line(label: 'Delivery', value: deliveryFeeCents),
              const Divider(height: Space.xl),
              _Line(label: 'Total', value: totalCents, emphasis: true),
              const SizedBox(height: Space.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Paid via $paymentMethod',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String? _formatTs(dynamic ts) {
    if (ts is! Timestamp) return null;
    return DateFormat('d MMM yyyy, h:mm a').format(ts.toDate());
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] as String?) ?? 'Item';
    final qty = (item['quantity'] as int?) ?? 1;
    final unitCents = (item['unitPriceCents'] as int?) ?? 0;
    final lineCents = unitCents * qty;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name × $qty',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            'LKR ${(lineCents / 100).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final int value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.primary)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('LKR ${(value / 100).toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
