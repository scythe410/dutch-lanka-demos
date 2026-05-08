import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_line_item.dart';

/// In-memory cart. Per CLAUDE.md rule 5, the cart never touches Firestore
/// until [createOrder] is called at checkout.
class CartNotifier extends StateNotifier<Map<String, CartLineItem>> {
  CartNotifier() : super(const {});

  void add(Product product, {int qty = 1}) {
    final existing = state[product.id];
    final next = existing == null
        ? CartLineItem.fromProduct(product, qty: qty)
        : existing.copyWith(qty: existing.qty + qty);
    state = {...state, product.id: next};
  }

  void setQty(String productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    final existing = state[productId];
    if (existing == null) return;
    state = {...state, productId: existing.copyWith(qty: qty)};
  }

  void remove(String productId) {
    final next = {...state}..remove(productId);
    state = next;
  }

  void clear() => state = const {};
}

final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, CartLineItem>>(
  (ref) => CartNotifier(),
);

/// Total item count across all lines. Used by the home-screen cart badge.
final cartItemCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartProvider)
      .values
      .fold<int>(0, (sum, line) => sum + line.qty);
});

/// Sum of `unitPrice * qty` in cents.
final cartTotalCentsProvider = Provider<int>((ref) {
  return ref
      .watch(cartProvider)
      .values
      .fold<int>(0, (sum, line) => sum + line.lineTotalCents);
});
