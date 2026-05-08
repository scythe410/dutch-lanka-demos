import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ProductDetailPanel renders title, price, CTA', (tester) async {
    var qty = 1;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return ProductDetailPanel(
              imageWidget: Container(color: const Color(0xFFEFD9B0)),
              title: 'Butter Croissant',
              priceLabel: 'LKR 350.00',
              description: 'Laminated, all-butter, baked fresh.',
              rating: 4.5,
              quantity: qty,
              onQuantityChanged: (v) => setState(() => qty = v),
              onBack: () {},
              onFavoriteToggle: () {},
              onAddToCart: () {},
            );
          },
        ),
      ),
    );

    expect(find.text('Butter Croissant'), findsOneWidget);
    expect(find.text('LKR 350.00'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProductDetailPanel quantity changes propagate', (tester) async {
    var qty = 1;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return ProductDetailPanel(
              imageWidget: Container(color: const Color(0xFFEFD9B0)),
              title: 'Croissant',
              priceLabel: 'LKR 350.00',
              description: 'desc',
              rating: 4.0,
              quantity: qty,
              onQuantityChanged: (v) => setState(() => qty = v),
              onAddToCart: () {},
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(qty, 2);
  });
}
