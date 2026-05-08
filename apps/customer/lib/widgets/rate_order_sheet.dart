import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reviews_provider.dart';

/// Bottom-sheet review form. We rate one product per submission, so the
/// sheet first lists the items in the order; tapping one reveals the
/// stars + comment fields. Each submission writes a single doc to
/// `/products/{productId}/reviews/{auto}`.
class RateOrderSheet extends ConsumerStatefulWidget {
  const RateOrderSheet({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  ConsumerState<RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends ConsumerState<RateOrderSheet> {
  String? _selectedProductId;
  String? _selectedProductName;
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _confirmation;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pid = _selectedProductId;
    if (pid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(submitReviewProvider)(
        productId: pid,
        rating: _rating,
        comment: _comment.text,
      );
      if (!mounted) return;
      setState(() {
        _confirmation = 'Thanks for rating $_selectedProductName!';
        _selectedProductId = null;
        _selectedProductName = null;
        _rating = 5;
        _comment.clear();
      });
    } catch (e) {
      setState(() => _error = 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(AppRadius.dragHandle),
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            _selectedProductId == null ? 'Rate your order' : 'Rate $_selectedProductName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.md),
          if (_selectedProductId == null)
            ..._buildProductChooser(items)
          else
            ..._buildRatingForm(),
          if (_confirmation != null) ...[
            const SizedBox(height: Space.md),
            Text(
              _confirmation!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildProductChooser(List<dynamic> items) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          child: Text(
            "We couldn't find any items on this order.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ];
    }
    return [
      for (final raw in items)
        if (raw is Map)
          _ProductChoice(
            name: (raw['name'] as String?) ?? 'Item',
            qty: (raw['quantity'] as int?) ?? 1,
            onTap: () => setState(() {
              _selectedProductId = raw['productId'] as String?;
              _selectedProductName = (raw['name'] as String?) ?? 'this item';
            }),
          ),
    ];
  }

  List<Widget> _buildRatingForm() {
    return [
      _StarRow(
        rating: _rating,
        onChanged: (v) => setState(() => _rating = v),
      ),
      const SizedBox(height: Space.lg),
      AppTextField(
        controller: _comment,
        label: 'Comments (optional)',
        hint: 'Tell us what you liked',
      ),
      const SizedBox(height: Space.lg),
      PrimaryButton(
        label: 'Submit rating',
        icon: LucideIcons.star,
        onPressed: _saving ? null : _submit,
      ),
      const SizedBox(height: Space.sm),
      TextButton(
        onPressed: () => setState(() => _selectedProductId = null),
        child: const Text(
          'Choose a different item',
          style: TextStyle(color: AppColors.primary),
        ),
      ),
    ];
  }
}

class _ProductChoice extends StatelessWidget {
  const _ProductChoice({
    required this.name,
    required this.qty,
    required this.onTap,
  });

  final String name;
  final int qty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                const IconTile(icon: LucideIcons.star),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    '$name × $qty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(
                  LucideIcons.chevron_right,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: 36,
            icon: Icon(
              i <= rating ? LucideIcons.star : LucideIcons.star,
              color: i <= rating ? AppColors.primary : AppColors.muted,
            ),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }
}
