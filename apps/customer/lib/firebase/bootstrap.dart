import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Wires up the production-grade Firebase services that the app entry-points
/// share: App Check, Crashlytics, Performance Monitoring, and the global
/// Flutter error handler.
///
/// Must be called *after* `Firebase.initializeApp` and *before* `runApp`.
Future<void> initFirebaseHardening({required bool isProd}) async {
  // App Check ---------------------------------------------------------------
  // Dev builds use the debug provider so simulators/emulators can pass the
  // attestation gate. The first run prints a debug token to logcat / Xcode
  // console — paste it into Firebase Console → App Check → Apps → "Manage
  // debug tokens" to whitelist that device.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        isProd ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: isProd ? AppleProvider.deviceCheck : AppleProvider.debug,
  );

  // Crashlytics -------------------------------------------------------------
  // Disabled in debug to avoid noise. Hooks into Flutter's framework error
  // channel + the platform dispatcher (covers async errors that escape the
  // widget tree). The global error boundary forwards FlutterErrorDetails
  // here as well.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  // installErrorBoundary owns FlutterError.onError so the framework error
  // channel and the fallback ErrorWidget are wired in lockstep.
  installErrorBoundary(
    reporter: FirebaseCrashlytics.instance.recordFlutterError,
  );
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Performance Monitoring --------------------------------------------------
  // Auto-traces network calls + screen rendering. Off in debug to keep
  // local runs fast and the prod board uncluttered.
  await FirebasePerformance.instance
      .setPerformanceCollectionEnabled(!kDebugMode);
}
