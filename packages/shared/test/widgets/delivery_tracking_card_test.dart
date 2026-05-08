import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('DeliveryTrackingCard renders courier name, ETA, location',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DeliveryTrackingCard(
              courierName: 'Anuradha P.',
              etaLabel: 'Arriving in 8 min',
              locationLabel: '450m away · Reid Avenue',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Anuradha P.'), findsOneWidget);
    expect(find.text('Food Courier'), findsOneWidget);
    expect(find.text('Arriving in 8 min'), findsOneWidget);
    expect(find.text('450m away · Reid Avenue'), findsOneWidget);
  });

  testWidgets('DeliveryTrackingCard call button fires callback',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DeliveryTrackingCard(
              courierName: 'Anuradha P.',
              etaLabel: 'Arriving in 8 min',
              locationLabel: 'On the way',
              onCallPressed: () => calls += 1,
              scallopedTop: false,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkResponse));
    await tester.pump();
    expect(calls, 1);
  });
}
