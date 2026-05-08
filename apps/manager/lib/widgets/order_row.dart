import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

const orderStatusLabels = {
  'pending_payment': 'Pending payment',
  'paid': 'Paid',
  'preparing': 'Preparing',
  'dispatched': 'Dispatched',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

/// Compact order row for the dashboard / orders list. Manager-side rows
/// emphasise data density: customer name + total + status pill + a
/// small relative-time caption. No images.
class OrderRow extends StatelessWidget {
  const OrderRow({super.key, required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = (order['id'] as String?) ?? '';
    final name = (order['customerName'] as String?) ?? 'Customer';
    final status = (order['status'] as String?) ?? 'paid';
    final totalCents = (order['totalCents'] as int?) ?? 0;
    final createdAt = order['createdAt'];
    final created = createdAt is Timestamp
        ? DateFormat('h:mm a').format(createdAt.toDate())
        : '—';

    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              const IconTile(icon: LucideIcons.shopping_bag),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${id.isEmpty ? '------' : id.substring(0, id.length.clamp(0, 6))} · $created',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${(totalCents / 100).toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  StatusPill(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final inProgress = status == 'paid' ||
        status == 'preparing' ||
        status == 'dispatched';
    final filled = inProgress;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        border: filled
            ? null
            : Border.all(color: AppColors.muted.withValues(alpha: 0.4)),
      ),
      child: Text(
        orderStatusLabels[status] ?? status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: filled ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
