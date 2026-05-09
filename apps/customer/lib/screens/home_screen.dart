import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_image.dart';

const _allCategory = '_all';

String _formatLkr(int cents) => 'LKR ${(cents / 100).toStringAsFixed(2)}';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = _allCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _applyFilters(List<Product> products) {
    final q = _query.trim().toLowerCase();
    return products.where((p) {
      if (_category != _allCategory && p.category != _category) return false;
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  List<String> _categories(List<Product> products) {
    final set = <String>{};
    for (final p in products) {
      set.add(p.category);
    }
    final list = set.toList()..sort();
    return [_allCategory, ...list];
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const TwoToneTitle(
          black: 'Dutch',
          orange: 'Lanka',
          orangeLeads: false,
        ),
        actions: [
          _CartBadge(count: cartCount),
          IconButton(
            tooltip: 'Orders',
            icon: const Icon(LucideIcons.shopping_bag, color: AppColors.primary),
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(LucideIcons.user, color: AppColors.primary),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load the menu. Please try again in a moment.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (products) {
          final categories = _categories(products);
          final filtered = _applyFilters(products);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.lg,
                  Space.xl,
                  Space.md,
                ),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Space.xl),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return _CategoryPill(
                      label: c == _allCategory ? 'All' : _humanize(c),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    );
                  },
                ),
              ),
              const SizedBox(height: Space.md),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No products match — try a different search.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          Space.xl,
                          0,
                          Space.xl,
                          Space.xl,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Space.lg,
                          mainAxisSpacing: Space.lg,
                          // Card is square image (1:1 = full width tall) plus
                          // body (16 padding + title + 4 + price + 8 + stars
                          // + 16 padding ≈ 110 dp on a Pixel 8 with default
                          // font scale). 0.58 leaves real headroom — 0.62
                          // was off by ~1.5 dp once the star row was drawn.
                          childAspectRatio: 0.58,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return ProductCard(
                            title: p.name,
                            priceLabel: _formatLkr(p.priceCents),
                            rating: 4.5,
                            imageWidget: ProductImage(imagePath: p.imagePath),
                            onTap: () => context.push('/product/${p.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _humanize(String category) =>
    category.isEmpty ? '' : category[0].toUpperCase() + category.substring(1);

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: Space.md),
          child: Icon(LucideIcons.search, color: AppColors.primary),
        ),
        Expanded(
          child: AppTextField(
            controller: controller,
            hint: "Search the menu",
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.onPrimary;
    final fg = selected ? AppColors.onPrimary : AppColors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Cart',
          icon: const Icon(LucideIcons.shopping_cart, color: AppColors.primary),
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: appTextTheme.bodySmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
