import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Mirrors the customer-app helper: enables App Check, Crashlytics, and
/// Performance Monitoring, then installs the shared error boundary.
///
/// Must be called *after* `Firebase.initializeApp` and *before* `runApp`.
Future<void> initFirebaseHardening({required bool isProd}) async {
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        isProd ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: isProd ? AppleProvider.deviceCheck : AppleProvider.debug,
  );

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  installErrorBoundary(
    reporter: FirebaseCrashlytics.instance.recordFlutterError,
  );
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebasePerformance.instance
      .setPerformanceCollectionEnabled(!kDebugMode);
}
