import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Set via `--dart-define=USE_EMULATOR=true` at run/build time.
const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

/// Optional override for the emulator host — useful when running on a
/// **physical Android device** with `adb reverse` forwarding the laptop's
/// emulator ports back to the phone. Pass `--dart-define=EMULATOR_HOST=localhost`.
const _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// Android emulators route the host machine's localhost to 10.0.2.2;
/// iOS simulators and desktop builds use plain localhost. With `adb reverse`
/// on a real device, pass EMULATOR_HOST=localhost to skip the AVD-only
/// 10.0.2.2 mapping.
String _emulatorHost() {
  if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
  if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}

/// Point every Firebase SDK at the local emulator suite. Must be called
/// after `Firebase.initializeApp` and before any reads/writes.
Future<void> connectToEmulators() async {
  if (!useEmulator) return;
  final host = _emulatorHost();
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instanceFor(region: 'asia-south1')
      .useFunctionsEmulator(host, 5001);
  appLogger.i('Firebase: connected to emulators at $host');
}
