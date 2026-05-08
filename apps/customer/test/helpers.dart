import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dutch_lanka_customer/providers/auth_provider.dart';

class FakeFirebaseAuth extends Mock implements FirebaseAuth {}

class FakeUser extends Mock implements User {}

/// Wraps a screen in `MaterialApp(theme: appTheme)` + `ProviderScope` so
/// `Theme.of`, `Directionality`, and Riverpod overrides are available.
Widget wrap(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: appTheme,
      home: child,
    ),
  );
}

/// Convenience: an override that gives every read of [firebaseAuthProvider]
/// the same [FakeFirebaseAuth]. Stub it inline before pumping.
Override fakeAuthOverride(FakeFirebaseAuth fake) =>
    firebaseAuthProvider.overrideWithValue(fake);
