import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('AppTextField builds and accepts input', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      wrap(AppTextField(
        controller: controller,
        label: 'Email',
        hint: 'you@example.com',
      )),
    );

    expect(find.text('EMAIL'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.co');
    expect(controller.text, 'a@b.co');
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppTextField renders helper text', (tester) async {
    await tester.pumpWidget(
      wrap(const AppTextField(helperText: 'We never share your email')),
    );

    expect(find.text('We never share your email'), findsOneWidget);
  });

  testWidgets('AppTextField renders error text in place of helper', (tester) async {
    await tester.pumpWidget(
      wrap(const AppTextField(
        helperText: 'helper',
        errorText: 'something went wrong',
      )),
    );

    expect(find.text('something went wrong'), findsOneWidget);
    expect(find.text('helper'), findsNothing);
  });
}
