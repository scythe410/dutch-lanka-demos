import 'dart:ui';

import 'package:dutch_lanka_manager/providers/orders_provider.dart';
import 'package:dutch_lanka_manager/providers/users_provider.dart';
import 'package:dutch_lanka_manager/screens/order_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('OrderDetailScreen renders sections for a paid order',
      (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());

    final order = {
      'id': 'o1',
      'customerName': 'Anuradha P.',
      'customerPhone': '+94 71 555 5555',
      'status': 'paid',
      'totalCents': 25000,
      'subtotalCents': 22000,
      'deliveryFeeCents': 3000,
      'items': [
        {'name': 'Croissant', 'quantity': 2, 'unitPriceCents': 11000},
      ],
      'deliveryAddress': {'line1': '12 Galle Rd', 'city': 'Colombo'},
      'assignedDeliveryUid': null,
    };

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        const OrderDetailScreen(orderId: 'o1'),
        overrides: [
          fakeAuthOverride(auth),
          orderByIdProvider('o1').overrideWith((_) => Stream.value(order)),
          staffUsersProvider.overrideWith((_) => Stream.value(const [])),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Anuradha P.'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Assign delivery'), findsOneWidget);
    expect(find.text('Mark as Preparing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
