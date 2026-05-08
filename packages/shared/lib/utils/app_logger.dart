import 'package:logger/logger.dart';

/// Single shared `Logger` instance for both apps. Replaces stray `print` /
/// `debugPrint` calls. The `Logger` package writes to the platform console
/// in debug builds and is silenced in release through `Level.warning` so
/// only meaningful events reach Crashlytics' breadcrumb stream.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: false,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.info,
);
