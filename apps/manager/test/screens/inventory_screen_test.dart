import 'package:dutch_lanka_manager/providers/inventory_provider.dart';
import 'package:dutch_lanka_manager/screens/inventory_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('InventoryScreen empty state', (tester) async {
    await tester.pumpWidget(
      wrap(
        const InventoryScreen(),
        overrides: [
          lowStockAlertsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('All stocks are healthy.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InventoryScreen renders alerts', (tester) async {
    final alert = {
      'id': 'a1',
      'productName': 'Croissant',
      'stock': 2,
      'threshold': 5,
    };
    await tester.pumpWidget(
      wrap(
        const InventoryScreen(),
        overrides: [
          lowStockAlertsProvider.overrideWith((_) => Stream.value([alert])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.textContaining('Stock 2 · threshold 5'), findsOneWidget);
    expect(find.text('Mark resolved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
