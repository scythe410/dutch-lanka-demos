import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_image.dart';

final _detailQtyProvider =
    StateProvider.autoDispose.family<int, String>((ref, _) => 1);

String _formatLkr(int cents) => 'LKR ${(cents / 100).toStringAsFixed(2)}';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? const {};
    final qty = ref.watch(_detailQtyProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load this product.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(
                  'This product is no longer available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ProductDetailPanel(
            imageWidget: ProductImage(
              imagePath: product.imagePath,
              fit: BoxFit.cover,
            ),
            title: product.name,
            priceLabel: _formatLkr(product.priceCents * qty),
            description: product.description,
            rating: 4.5,
            quantity: qty,
            onQuantityChanged: (v) =>
                ref.read(_detailQtyProvider(productId).notifier).state = v,
            favorite: favorites.contains(product.id),
            onFavoriteToggle: () => toggleFavorite(ref, product.id),
            onBack: () => context.pop(),
            onAddToCart: () {
              ref.read(cartProvider.notifier).add(product, qty: qty);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $qty × ${product.name} to cart.')),
              );
            },
          );
        },
      ),
    );
  }
}
