import 'package:dutch_lanka_manager/providers/complaints_provider.dart';
import 'package:dutch_lanka_manager/screens/more/complaints_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ComplaintsScreen empty state', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ComplaintsScreen(),
        overrides: [
          complaintsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('No complaints. Nice work!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ComplaintsScreen renders an open complaint', (tester) async {
    final c = {
      'id': 'c1',
      'subject': 'Late delivery',
      'body': 'Order took 90 minutes.',
      'status': 'open',
    };
    await tester.pumpWidget(
      wrap(
        const ComplaintsScreen(),
        overrides: [
          complaintsProvider.overrideWith((_) => Stream.value([c])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Late delivery'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Mark resolved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
