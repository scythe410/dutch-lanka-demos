import 'package:dutch_lanka_manager/providers/reports_provider.dart';
import 'package:dutch_lanka_manager/screens/more/reports_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ReportsScreen renders both chart cards', (tester) async {
    final daily = [
      for (var i = 0; i < 7; i++)
        DailyTotal(DateTime(2026, 5, i + 1), (i + 1) * 1000),
    ];
    final top = const [
      ProductTotal('Croissant', 30),
      ProductTotal('Banis', 18),
    ];
    await tester.pumpWidget(
      wrap(
        const ReportsScreen(),
        overrides: [
          dailySalesProvider.overrideWith((_) => Stream.value(daily)),
          topProductsProvider.overrideWith((_) => Stream.value(top)),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Sales — last 7 days'), findsOneWidget);
    expect(find.text('Top products — last 30 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReportsScreen empty state for top products', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ReportsScreen(),
        overrides: [
          dailySalesProvider.overrideWith((_) => Stream.value(const [])),
          topProductsProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('No sales in the last 30 days.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
