import 'package:dutch_lanka_customer/screens/forgot_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('ForgotPasswordScreen builds and shows Send reset link CTA',
      (tester) async {
    await tester.pumpWidget(wrap(const ForgotPasswordScreen()));
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Back to log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
