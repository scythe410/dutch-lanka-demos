import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_image.dart';

const _allCategory = '_all';

String _formatLkr(int cents) =>
    'LKR ${(cents / 100).toStringAsFixed(0)}';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Image.asset(
          'assets/branding/dutch-logo-on-black.png',
          height: 28,
          fit: BoxFit.fitHeight,
        ),
        centerTitle: false,
        actions: [
          _CartBadge(count: cartCount),
          IconButton(
            tooltip: 'Orders',
            icon: const Icon(LucideIcons.shopping_bag),
            color: AppColors.onSurface,
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(LucideIcons.user),
            color: AppColors.onSurface,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (products) {
          final categories = _categories(products);
          final filtered = _applyFilters(products);
          return CustomScrollView(
            slivers: [
              // ── Search ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    Space.lg,
                    Space.xl,
                    0,
                  ),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),

              // ── Hero combo banner ────────────────────────────────
              if (_query.isEmpty && _category == _allCategory)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xl,
                      Space.lg,
                      Space.xl,
                      0,
                    ),
                    child: _HeroBanner(
                      onTap: () {
                        setState(() => _category = _allCategory);
                      },
                    ),
                  ),
                ),

              // ── Category pills ────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl,
                      vertical: Space.sm,
                    ),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: Space.sm),
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
              ),

              // ── Section header ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.xl,
                  Space.xl,
                  Space.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "TONIGHT'S MENU.",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppColors.onSurface),
                      ),
                      Text(
                        '${filtered.length} ITEMS',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Product grid ─────────────────────────────────────
              filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No products match — try a different search.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.xl,
                        0,
                        Space.xl,
                        Space.xl,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Space.md,
                          mainAxisSpacing: Space.md,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final p = filtered[i];
                            return ProductCard(
                              title: p.name,
                              priceLabel: _formatLkr(p.priceCents),
                              rating: 4.5,
                              imageWidget:
                                  ProductImage(imagePath: p.imagePath),
                              onTap: () =>
                                  context.push('/product/${p.id}'),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.lineStrong),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1208)],
          ),
        ),
        child: Stack(
          children: [
            // Yellow glow from top-right
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Corner ribbon
            Positioned(
              top: Space.md,
              left: Space.md,
              child: _Ribbon(label: 'COMBO'),
            ),
            Positioned(
              top: Space.md,
              right: Space.md,
              child: _Ribbon(
                label: 'NEW TONIGHT',
                ghost: true,
              ),
            ),

            // Text content
            Positioned(
              left: Space.lg,
              bottom: Space.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TONIGHT'S",
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 28,
                          height: 0.95,
                        ),
                  ),
                  Text(
                    'MENU.',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(
                          color: AppColors.primary,
                          fontSize: 28,
                          height: 0.95,
                        ),
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.flame,
                        size: 13,
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        'Open from 6 PM · order now',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow CTA
            Positioned(
              right: Space.lg,
              bottom: Space.lg,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrow_right,
                  size: 20,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label, this.ghost = false});

  final String label;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: ghost ? Colors.transparent : AppColors.accentRed,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: ghost ? Border.all(color: AppColors.lineStrong) : null,
      ),
      child: Text(
        label,
        style: appTextTheme.labelSmall?.copyWith(
          color: ghost ? AppColors.onSurface : Colors.white,
        ),
      ),
    );
  }
}

// ── Search ───────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.lineStrong),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 18, color: AppColors.muted),
          const SizedBox(width: Space.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search the kitchen…',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category pill ─────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.buttonPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.lineStrong,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

// ── Cart badge ────────────────────────────────────────────────────────────────

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
          icon: const Icon(LucideIcons.shopping_cart),
          color: AppColors.onSurface,
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
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
                style: appTextTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _humanize(String c) =>
    c.isEmpty ? '' : c[0].toUpperCase() + c.substring(1);
