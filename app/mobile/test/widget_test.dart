import 'package:flutter_test/flutter_test.dart';

import 'package:signaldesk_mobile/src/app.dart';

void main() {
  testWidgets('SignalDesk app renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SignalDeskApp());
    await tester.pumpAndSettle();

    expect(find.text('SignalDesk Home'), findsOneWidget);
  });
}
