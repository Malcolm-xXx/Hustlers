import 'package:flutter_test/flutter_test.dart';

import 'package:hustlers/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HustlersApp());
    await tester.pump();

    expect(find.text('Hustlers'), findsOneWidget);
  });
}
