import 'package:dutch_lanka_manager/providers/users_provider.dart';
import 'package:dutch_lanka_manager/screens/more/customers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('CustomersScreen renders rows + filters by query', (tester) async {
    final rows = [
      {'id': 'u1', 'name': 'Anuradha P.', 'email': 'a@x.com', 'phone': '555-1'},
      {'id': 'u2', 'name': 'Kavindu', 'email': 'k@x.com', 'phone': '555-2'},
    ];
    await tester.pumpWidget(
      wrap(
        const CustomersScreen(),
        overrides: [
          customerUsersProvider.overrideWith((_) => Stream.value(rows)),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Anuradha P.'), findsOneWidget);
    expect(find.text('Kavindu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kav');
    await tester.pump();

    expect(find.text('Anuradha P.'), findsNothing);
    expect(find.text('Kavindu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
