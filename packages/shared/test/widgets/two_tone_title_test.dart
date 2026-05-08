import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('TwoToneTitle renders both halves', (tester) async {
    await tester.pumpWidget(
      wrap(const TwoToneTitle(black: 'Welcome', orange: 'to Dutch Lanka!')),
    );

    expect(find.byType(RichText), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TwoToneTitle accepts orangeLeads flag', (tester) async {
    await tester.pumpWidget(
      wrap(const TwoToneTitle(
        black: 'Pages',
        orange: 'Other',
        orangeLeads: true,
      )),
    );

    expect(tester.takeException(), isNull);
  });
}
