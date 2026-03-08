import 'package:flutter_test/flutter_test.dart';
import 'package:signaldesk_mobile/src/app.dart';

void main() {
  testWidgets('SignalDesk app boots with home shell', (tester) async {
    await tester.pumpWidget(const SignalDeskApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Keyword Ranking'), findsWidgets);
  });
}
