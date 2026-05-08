import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('QuantityStepper increments and decrements', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      wrap(StatefulBuilder(
        builder: (context, setState) {
          return QuantityStepper(
            value: value,
            onChanged: (v) => setState(() => value = v),
          );
        },
      )),
    );

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('QuantityStepper supports onOrange variant', (tester) async {
    await tester.pumpWidget(
      wrap(QuantityStepper(
        value: 3,
        onChanged: (_) {},
        variant: QuantityStepperVariant.onOrange,
      )),
    );

    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
