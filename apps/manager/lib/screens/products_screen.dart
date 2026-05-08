import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/products_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'All', orange: 'products'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load products.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products yet — tap + to add one.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) => _ProductRow(product: products[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => context.push('/products/new'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add product'),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final id = product['id'] as String? ?? '';
    final name = (product['name'] as String?) ?? 'Product';
    final category = (product['category'] as String?) ?? '—';
    final stock = (product['stock'] as int?) ?? 0;
    final threshold = (product['lowStockThreshold'] as int?) ?? 0;
    final priceCents = (product['priceCents'] as int?) ?? 0;
    final available = product['available'] as bool? ?? true;
    final lowStock = stock <= threshold;

    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/products/$id/edit'),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              IconTile(icon: LucideIcons.box, active: available),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$category · LKR ${(priceCents / 100).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$stock in stock',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: lowStock
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight:
                              lowStock ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                  if (!available)
                    Text(
                      'Off-menu',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
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
