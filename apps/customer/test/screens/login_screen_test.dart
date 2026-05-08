import 'package:dutch_lanka_customer/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('LoginScreen builds and shows Log In CTA', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
