import 'package:dutch_lanka_manager/providers/users_provider.dart';
import 'package:dutch_lanka_manager/screens/more/staff_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('StaffScreen renders staff rows + Promote section',
      (tester) async {
    final rows = [
      {'id': 'u1', 'uid': 'u1', 'name': 'Mgr One', 'email': 'm@x.com', 'role': 'manager'},
      {'id': 'u2', 'uid': 'u2', 'name': 'Staffer', 'email': 's@x.com', 'role': 'staff'},
    ];
    await tester.pumpWidget(
      wrap(
        const StaffScreen(),
        overrides: [
          staffUsersProvider.overrideWith((_) => Stream.value(rows)),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Mgr One'), findsOneWidget);
    expect(find.text('Staffer'), findsOneWidget);
    expect(find.text('Promote a customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
