import 'package:dutch_lanka_manager/screens/more/about_screen.dart';
import 'package:dutch_lanka_manager/screens/more/more_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('MoreScreen lists each tool + Sign out', (tester) async {
    final auth = FakeFirebaseAuth();
    when(() => auth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      wrap(
        const MoreScreen(),
        overrides: [fakeAuthOverride(auth)],
      ),
    );
    await tester.pump();
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Complaints'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('SIGN OUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AboutScreen renders headline', (tester) async {
    await tester.pumpWidget(wrap(const AboutScreen()));
    await tester.pump();
    expect(find.text('Dutch Lanka — Manager console'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
