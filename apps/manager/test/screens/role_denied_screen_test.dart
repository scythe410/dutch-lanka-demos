import 'package:dutch_lanka_manager/screens/role_denied_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('RoleDeniedScreen explains denial + Sign out CTA',
      (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      wrap(
        const RoleDeniedScreen(),
        overrides: [fakeAuthOverride(auth)],
      ),
    );
    await tester.pump();
    expect(find.text('Access denied'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
