import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('IconTile renders the given icon', (tester) async {
    await tester.pumpWidget(
      wrap(const IconTile(icon: Icons.shopping_cart)),
    );

    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('IconTile fires onTap when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(IconTile(icon: Icons.notifications, onTap: () => taps++)),
    );

    await tester.tap(find.byType(IconTile));
    expect(taps, 1);
  });

  testWidgets('IconTile inactive variant builds', (tester) async {
    await tester.pumpWidget(
      wrap(const IconTile(icon: Icons.notifications, active: false)),
    );

    expect(tester.takeException(), isNull);
  });
}
