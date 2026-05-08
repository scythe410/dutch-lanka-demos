import 'package:dutch_lanka_manager/providers/products_provider.dart';
import 'package:dutch_lanka_manager/screens/products_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ProductsScreen empty state', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProductsScreen(),
        overrides: [
          allProductsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('No products yet — tap + to add one.'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProductsScreen renders rows with stock badge', (tester) async {
    final product = {
      'id': 'p1',
      'name': 'Croissant',
      'category': 'pastry',
      'stock': 2,
      'lowStockThreshold': 5,
      'priceCents': 35000,
      'available': true,
    };
    await tester.pumpWidget(
      wrap(
        const ProductsScreen(),
        overrides: [
          allProductsProvider.overrideWith((_) => Stream.value([product])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('2 in stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
