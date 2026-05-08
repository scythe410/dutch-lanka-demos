import 'package:dutch_lanka_manager/providers/orders_provider.dart';
import 'package:dutch_lanka_manager/screens/orders_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('OrdersScreen renders empty state', (tester) async {
    await tester.pumpWidget(
      wrap(
        const OrdersScreen(),
        overrides: [
          allOrdersProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('No orders yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OrdersScreen lists rows', (tester) async {
    final order = {
      'id': 'o1',
      'customerName': 'Customer 1',
      'status': 'preparing',
      'totalCents': 12000,
    };
    await tester.pumpWidget(
      wrap(
        const OrdersScreen(),
        overrides: [
          allOrdersProvider.overrideWith((_) => Stream.value([order])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Customer 1'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
