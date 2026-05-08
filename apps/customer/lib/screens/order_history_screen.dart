import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';
import '../widgets/rate_order_sheet.dart';

const _statusLabels = {
  'pending_payment': 'Awaiting payment',
  'paid': 'Paid',
  'preparing': 'Preparing',
  'dispatched': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

/// Statuses where the order is still moving — tap routes to live tracking.
/// Anything else opens the read-only summary.
const _inProgressStatuses = {'paid', 'preparing', 'dispatched'};

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Your', orange: 'orders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load your orders right now.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.md),
            itemBuilder: (context, i) => _OrderRow(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final id = order['id'] as String;
    final status = (order['status'] as String?) ?? 'pending_payment';
    final totalCents = (order['totalCents'] as int?) ?? 0;
    final createdAt = order['createdAt'];
    final createdAtLabel = createdAt is Timestamp
        ? DateFormat('d MMM, h:mm a').format(createdAt.toDate())
        : '—';
    final inProgress = _inProgressStatuses.contains(status);
    final delivered = status == 'delivered';

    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          if (inProgress) {
            context.push('/order/$id');
          } else {
            context.push('/order/$id/summary');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${id.substring(0, id.length.clamp(0, 6))}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      createdAtLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        _StatusPill(status: status),
                        if (delivered) ...[
                          const SizedBox(width: Space.sm),
                          _RateButton(order: order),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${(totalCents / 100).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: Space.sm),
                  const Icon(
                    LucideIcons.chevron_right,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.buttonPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
          ),
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: RateOrderSheet(order: order),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.star, size: 14, color: AppColors.onPrimary),
              const SizedBox(width: Space.xs),
              Text(
                'Rate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == 'delivered';
    final cancelled = status == 'cancelled';
    final filled = !delivered && !cancelled;
    final bg = filled ? AppColors.primary : AppColors.surface;
    final fg = filled ? AppColors.onPrimary : AppColors.onSurface;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        border: filled
            ? null
            : Border.all(color: AppColors.muted.withValues(alpha: 0.5)),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.shopping_bag,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: Space.lg),
            Text(
              'No orders yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'When you place an order it will show up here so you '
              'can track it live.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
