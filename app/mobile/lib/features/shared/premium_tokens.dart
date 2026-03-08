import 'package:flutter/material.dart';

abstract final class SignalDeskSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}

abstract final class SignalDeskShape {
  static final card = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  static final secondary = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  );
}

abstract final class SignalDeskPalette {
  static const momentumUp = Color(0xFF157347);
  static const momentumDown = Color(0xFFB3261E);
  static const trustHigh = Color(0xFF0A7A5A);
  static const trustMid = Color(0xFF8A6D1A);
  static const trustLow = Color(0xFF8A1A3B);
  static const risk = Color(0xFFB42318);
}
