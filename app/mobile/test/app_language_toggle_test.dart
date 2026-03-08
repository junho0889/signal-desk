import 'package:flutter_test/flutter_test.dart';
import 'package:signaldesk_mobile/core/localization/app_localization.dart';
import 'package:signaldesk_mobile/src/app.dart';

void main() {
  testWidgets('app shell language toggle switches home chrome', (tester) async {
    const app = SignalDeskApp();
    const english = AppStrings(AppLanguage.english);
    const korean = AppStrings(AppLanguage.korean);

    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.text(english.homeTitle), findsOneWidget);
    expect(find.text(english.languageToggleLabel), findsOneWidget);

    await tester.tap(find.text(english.languageToggleLabel));
    await tester.pump();

    expect(find.text(korean.homeTitle), findsOneWidget);
    expect(find.text(korean.languageToggleLabel), findsOneWidget);
  });
}
