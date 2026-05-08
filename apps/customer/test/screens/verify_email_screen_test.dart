import 'package:dutch_lanka_customer/screens/verify_email_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('VerifyEmailScreen builds and shows primary CTA', (tester) async {
    final auth = FakeFirebaseAuth();
    final user = FakeUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('hello@example.com');

    await tester.pumpWidget(
      wrap(
        const VerifyEmailScreen(pollingEnabled: false),
        overrides: [fakeAuthOverride(auth)],
      ),
    );

    expect(find.text("I've verified my email"), findsOneWidget);
    expect(find.text('hello@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
