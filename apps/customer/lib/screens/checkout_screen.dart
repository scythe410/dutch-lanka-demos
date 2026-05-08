import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/payhere_service.dart';

const _deliveryFeeCents = 30000; // mirrors the server-side flat fee.

const _paymentMethods = [
  ('card', 'Card'),
  ('ezcash', 'eZ Cash'),
  ('mcash', 'mCash'),
  ('genie', 'Genie'),
  ('frimi', 'FriMi'),
];

String _formatLkr(int cents) => 'LKR ${(cents / 100).toStringAsFixed(2)}';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  String _paymentMethod = 'card';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      _name.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _payNow() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _line1.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in name, phone, and address.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final createOrder = ref.read(createOrderCallableProvider);
      final result = await createOrder({
        'items': cart.values
            .map((line) => {
                  'productId': line.productId,
                  'qty': line.qty,
                  'unitPriceCents': line.unitPriceCents,
                })
            .toList(),
        'deliveryAddress': {
          'line1': _line1.text.trim(),
          'city': _city.text.trim(),
        },
        'paymentMethod': _paymentMethod,
        'customerName': _name.text.trim(),
        'customerPhone': _phone.text.trim(),
      });

      // Hand off to PayHere — but route to the tracking screen *before*
      // awaiting the SDK so the live `paymentStatus` listener mounts and
      // catches the server-side update even if the user backgrounds the
      // app during the sheet.
      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      context.replace('/order/${result.orderId}');

      // Fire-and-forget the SDK. The Future resolves when the sheet
      // closes; we ignore the outcome (CLAUDE.md rule 2).
      unawaited(
        const PayHereService().startPayment(result.payherePayload),
      );
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? 'Could not place the order. Please try again.';
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalCentsProvider);
    final total = subtotal + _deliveryFeeCents;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery to',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Space.md),
            AppTextField(controller: _name, label: 'Full name'),
            const SizedBox(height: Space.md),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: Space.md),
            AppTextField(controller: _line1, label: 'Address'),
            const SizedBox(height: Space.md),
            AppTextField(controller: _city, label: 'City'),

            const SizedBox(height: Space.xl),
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final (id, label) in _paymentMethods)
                  _MethodPill(
                    label: label,
                    selected: _paymentMethod == id,
                    onTap: () => setState(() => _paymentMethod = id),
                  ),
              ],
            ),

            const SizedBox(height: Space.xl),
            _SummaryRow(label: 'Items', value: _formatLkr(subtotal)),
            const SizedBox(height: Space.sm),
            _SummaryRow(
              label: 'Delivery',
              value: _formatLkr(_deliveryFeeCents),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Space.md),
              child: Divider(height: 1, color: AppColors.muted),
            ),
            _SummaryRow(label: 'Total', value: _formatLkr(total), bold: true),

            if (_error != null) ...[
              const SizedBox(height: Space.md),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
      bottomSheet: Container(
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
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _submitting
                  ? 'Placing order…'
                  : 'Pay ${_formatLkr(total)}',
              onPressed: (cart.isEmpty || _submitting) ? null : _payNow,
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({
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
        child: Text(
          label,
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final base = bold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: base),
        Text(
          value,
          style: bold ? base?.copyWith(color: AppColors.primary) : base,
        ),
      ],
    );
  }
}
