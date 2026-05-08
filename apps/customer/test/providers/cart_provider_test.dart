import 'package:dutch_lanka_customer/providers/cart_provider.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _croissant = Product(
  id: 'butter-croissant',
  name: 'Butter Croissant',
  description: '',
  category: 'pastry',
  priceCents: 35000,
);

const _kimbula = Product(
  id: 'kimbula-banis',
  name: 'Kimbula Banis',
  description: '',
  category: 'bread',
  priceCents: 8000,
);

void main() {
  ProviderContainer container() => ProviderContainer();

  test('add inserts a new line and increments quantity on repeat', () {
    final c = container();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.add(_croissant);
    expect(c.read(cartItemCountProvider), 1);

    notifier.add(_croissant, qty: 2);
    expect(c.read(cartProvider)[_croissant.id]!.qty, 3);
    expect(c.read(cartItemCountProvider), 3);
    expect(c.read(cartTotalCentsProvider), 35000 * 3);
  });

  test('setQty replaces, removes when <= 0', () {
    final c = container();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.add(_croissant, qty: 4);
    notifier.setQty(_croissant.id, 2);
    expect(c.read(cartProvider)[_croissant.id]!.qty, 2);

    notifier.setQty(_croissant.id, 0);
    expect(c.read(cartProvider).containsKey(_croissant.id), false);
  });

  test('cartTotalCents sums across multiple products', () {
    final c = container();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.add(_croissant, qty: 2); // 70000
    notifier.add(_kimbula, qty: 3); // 24000
    expect(c.read(cartTotalCentsProvider), 94000);
    expect(c.read(cartItemCountProvider), 5);
  });

  test('clear empties the cart', () {
    final c = container();
    addTearDown(c.dispose);
    final notifier = c.read(cartProvider.notifier);

    notifier.add(_croissant);
    notifier.clear();
    expect(c.read(cartProvider).isEmpty, true);
    expect(c.read(cartItemCountProvider), 0);
  });
}
