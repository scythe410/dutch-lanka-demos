import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('SecondaryButton renders label and fires callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(SecondaryButton(label: 'Add to cart', onPressed: () => taps++)),
    );

    expect(find.text('ADD TO CART'), findsOneWidget);
    await tester.tap(find.text('ADD TO CART'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
