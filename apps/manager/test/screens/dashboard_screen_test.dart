import 'package:dutch_lanka_manager/providers/inventory_provider.dart';
import 'package:dutch_lanka_manager/providers/orders_provider.dart';
import 'package:dutch_lanka_manager/screens/dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('DashboardScreen renders KPI tiles + empty orders', (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      wrap(
        const DashboardScreen(),
        overrides: [
          fakeAuthOverride(auth),
          incomingOrdersProvider.overrideWith((_) => Stream.value(const [])),
          todaysSalesCentsProvider.overrideWith((_) => Stream.value(123400)),
          lowStockAlertsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();

    expect(find.text("TODAY'S SALES · LIVE"), findsOneWidget);
    expect(find.text('ACTIVE ORDERS'), findsOneWidget);
    expect(find.text('LOW STOCK'), findsOneWidget);
    expect(find.text('LKR 1234'), findsOneWidget);
    expect(find.text('Incoming orders'), findsOneWidget);
    expect(find.text('No active orders right now.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardScreen lists incoming orders', (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());

    final order = {
      'id': 'order-1',
      'customerName': 'Anuradha P.',
      'status': 'paid',
      'totalCents': 25000,
    };

    await tester.pumpWidget(
      wrap(
        const DashboardScreen(),
        overrides: [
          fakeAuthOverride(auth),
          incomingOrdersProvider.overrideWith((_) => Stream.value([order])),
          todaysSalesCentsProvider.overrideWith((_) => Stream.value(0)),
          lowStockAlertsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Anuradha P.'), findsOneWidget);
    expect(find.text('LKR 250.00'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
