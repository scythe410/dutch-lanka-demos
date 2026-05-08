import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('OtpInput renders default 4 boxes', (tester) async {
    await tester.pumpWidget(wrap(const OtpInput()));

    expect(find.byType(TextField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('OtpInput renders configurable length', (tester) async {
    await tester.pumpWidget(wrap(const OtpInput(length: 6)));

    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('OtpInput fires onCompleted when full', (tester) async {
    String? completed;
    await tester.pumpWidget(
      wrap(OtpInput(onCompleted: (v) => completed = v)),
    );

    final fields = find.byType(TextField);
    for (var i = 0; i < 4; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }
    expect(completed, '1234');
  });
}
