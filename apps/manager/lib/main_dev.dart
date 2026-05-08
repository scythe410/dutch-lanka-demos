import 'dart:async';

import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'firebase/bootstrap.dart';
import 'firebase/emulator.dart';
import 'firebase/firebase_options_dev.dart';
import 'services/fcm_background.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env', mergeWith: const {});
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initFirebaseHardening(isProd: false);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await connectToEmulators();
    appLogger.i('Firebase initialized [dev]: ${app.options.projectId}');
    runApp(const App(environment: AppEnvironment.dev));
  }, (error, stack) {
    appLogger.e('Uncaught zone error', error: error, stackTrace: stack);
  });
}
