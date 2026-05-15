import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('KpiTile renders label and value', (tester) async {
    await tester.pumpWidget(
      wrap(const KpiTile(label: "Today's sales", value: 'LKR 24,500')),
    );

    expect(find.text("TODAY'S SALES"), findsOneWidget);
    expect(find.text('LKR 24,500'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('KpiTile shows chevron when onTap provided', (tester) async {
    await tester.pumpWidget(
      wrap(KpiTile(
        label: 'Active orders',
        value: '12',
        onTap: () {},
      )),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
