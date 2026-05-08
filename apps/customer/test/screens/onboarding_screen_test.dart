import 'package:dutch_lanka_customer/screens/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('OnboardingScreen builds and shows Next CTA', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
