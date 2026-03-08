import 'package:flutter/widgets.dart';

class SignalDeskAppScope extends InheritedWidget {
  const SignalDeskAppScope({
    super.key,
    required this.locale,
    required this.toggleLocale,
    required super.child,
  });

  final Locale locale;
  final VoidCallback toggleLocale;

  bool get isKorean => locale.languageCode == 'ko';

  static SignalDeskAppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SignalDeskAppScope>();
    assert(scope != null, 'SignalDeskAppScope is missing in widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SignalDeskAppScope oldWidget) {
    return oldWidget.locale != locale;
  }
}
