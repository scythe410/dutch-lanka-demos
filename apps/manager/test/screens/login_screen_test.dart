import 'package:dutch_lanka_manager/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('LoginScreen renders inputs and Sign in CTA', (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      wrap(
        const LoginScreen(),
        overrides: [fakeAuthOverride(auth)],
      ),
    );
    await tester.pump();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
