import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../widgets/product_image.dart';

String _formatLkr(int cents) => 'LKR ${(cents / 100).toStringAsFixed(2)}';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final lines = cart.values.toList();
    final total = ref.watch(cartTotalCentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart', style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(
                  'Your cart is empty.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.xl,
                160,
              ),
              itemCount: lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.md),
              itemBuilder: (context, i) => _CartLineTile(line: lines[i]),
            ),
      bottomSheet: lines.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.xl,
                Space.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _formatLkr(total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    PrimaryButton(
                      label: 'Checkout',
                      fullWidth: false,
                      onPressed: () => context.push('/checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line});

  final dynamic line; // CartLineItem — kept loose to avoid cross-file private import

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ProductImage(imagePath: line.imagePath as String?),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name as String,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLkr(line.lineTotalCents as int),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          QuantityStepper(
            value: line.qty as int,
            onChanged: (q) =>
                notifier.setQty(line.productId as String, q),
          ),
        ],
      ),
    );
  }
}
