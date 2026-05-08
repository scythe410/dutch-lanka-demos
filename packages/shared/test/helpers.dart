import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';

/// Wraps a widget in a `MaterialApp` with the shared theme so `Theme.of`,
/// `MediaQuery.of`, and `Directionality` are all available in widget tests.
Widget wrap(Widget child) {
  return MaterialApp(
    theme: appTheme,
    home: Scaffold(body: Center(child: child)),
  );
}
