import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import 'primary_button.dart';

/// Reporter callback signature — apps wire `FirebaseCrashlytics.instance.recordFlutterError`
/// (or equivalent) so the boundary stays free of any Firebase imports.
typedef ErrorReporter = void Function(FlutterErrorDetails details);

/// Installs a process-wide error handler that:
///   • forwards to [reporter] (Crashlytics in apps),
///   • shows the friendly fallback UI defined by [ErrorBoundary],
///   • avoids the default red-on-grey Flutter error screen in release.
///
/// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
void installErrorBoundary({required ErrorReporter reporter}) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    reporter(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Keep the verbose red screen during development — it helps catch
      // layout issues early.
      return ErrorWidget(details.exception);
    }
    return const _FallbackErrorScreen();
  };
}

class _FallbackErrorScreen extends StatelessWidget {
  const _FallbackErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: Space.lg),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: appTextTheme.headlineSmall,
              ),
              const SizedBox(height: Space.sm),
              Text(
                'We hit an unexpected error. You can try again — '
                'if it keeps happening, restart the app.',
                textAlign: TextAlign.center,
                style: appTextTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: 'Try again',
                onPressed: () {
                  // Pop back to the previous route if possible; otherwise
                  // attempt a forced rebuild by clearing the route stack.
                  final navigator = Navigator.maybeOf(context);
                  if (navigator != null && navigator.canPop()) {
                    navigator.pop();
                  } else {
                    // Best-effort soft reset — the host app's router will
                    // re-build the initial route on the next frame.
                    WidgetsBinding.instance
                        .reassembleApplication();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
