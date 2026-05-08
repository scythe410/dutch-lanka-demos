import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('PrimaryButton renders label and fires callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PrimaryButton(label: 'Get Started', onPressed: () => taps++)),
    );

    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PrimaryButton with null onPressed renders disabled', (tester) async {
    await tester.pumpWidget(
      wrap(const PrimaryButton(label: 'Disabled', onPressed: null)),
    );

    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, 0.4);
  });

  testWidgets('PrimaryButton accepts a leading icon', (tester) async {
    await tester.pumpWidget(
      wrap(PrimaryButton(
        label: 'Next',
        icon: Icons.arrow_forward,
        onPressed: () {},
      )),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
