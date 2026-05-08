import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler. Required to be top-level (not a
/// closure) because Firebase Messaging spawns a separate isolate to call
/// it. Currently a no-op — the OS already shows the notification when the
/// payload contains a `notification` block; tap routing happens in the
/// foreground via `onMessageOpenedApp`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate has no Firebase apps initialised yet — bring
  // them up before doing any Firebase work in the future.
  await Firebase.initializeApp();
}
