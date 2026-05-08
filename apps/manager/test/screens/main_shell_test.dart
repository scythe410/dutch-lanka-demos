import 'package:dutch_lanka_manager/screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('MainShell renders all four bottom-nav tabs', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MainShell(
          location: '/dashboard',
          child: Center(child: Text('CHILD')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('CHILD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
