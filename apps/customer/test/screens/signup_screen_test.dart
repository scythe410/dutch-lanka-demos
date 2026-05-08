import 'package:dutch_lanka_customer/screens/signup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('SignupScreen builds and shows Sign Up CTA', (tester) async {
    await tester.pumpWidget(wrap(const SignupScreen()));
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
