import 'dart:async';

import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'firebase/bootstrap.dart';
import 'firebase/firebase_options_prod.dart';
import 'services/fcm_background.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env', mergeWith: const {});
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initFirebaseHardening(isProd: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    appLogger.i('Firebase initialized [prod]: ${app.options.projectId}');
    runApp(const App(environment: AppEnvironment.prod));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
