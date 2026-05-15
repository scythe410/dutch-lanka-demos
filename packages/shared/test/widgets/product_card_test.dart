import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ProductCard renders title and price', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 200,
          child: ProductCard(
            title: 'Croissant',
            priceLabel: 'LKR 350',
            rating: 4.5,
            imageWidget: Container(color: const Color(0xFFCCCCCC)),
          ),
        ),
      ),
    );

    expect(find.text('CROISSANT'), findsOneWidget);
    expect(find.text('LKR 350'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProductCard fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 200,
          child: ProductCard(
            title: 'Donut',
            priceLabel: 'LKR 200',
            rating: 4.0,
            imageWidget: Container(color: const Color(0xFFCCCCCC)),
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ProductCard));
    await tester.pump();
    expect(taps, 1);
  });
}
