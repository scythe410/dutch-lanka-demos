import 'package:dutch_lanka_customer/providers/products_provider.dart';
import 'package:dutch_lanka_customer/screens/home_screen.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

const _seed = [
  Product(
    id: 'butter-croissant',
    name: 'Butter Croissant',
    description: 'Laminated, all-butter.',
    category: 'pastry',
    priceCents: 35000,
  ),
  Product(
    id: 'kimbula-banis',
    name: 'Kimbula Banis',
    description: 'Crocodile-shaped sweet bun.',
    category: 'bread',
    priceCents: 8000,
  ),
];

void main() {
  testWidgets('HomeScreen renders product grid + cart icon', (tester) async {
    final auth = FakeFirebaseAuth();
    final user = FakeUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('demo-customer');

    await tester.pumpWidget(
      wrap(
        const HomeScreen(),
        overrides: [
          fakeAuthOverride(auth),
          productsProvider.overrideWith((ref) => Stream.value(_seed)),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Butter Croissant'), findsOneWidget);
    expect(find.text('Kimbula Banis'), findsOneWidget);
    expect(find.byTooltip('Cart'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.byTooltip('Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
