# Branding assets

`app_icon.png` is the source PNG for `flutter_launcher_icons`. Replace the
seeded placeholder (currently the default Flutter icon) with the bakery
wordmark/logo before shipping:

- **Size:** 1024×1024 PNG, transparent or Soft Cream background
- **Safe area:** keep the wordmark within the inner 80% — adaptive Android
  icons crop the outer ring

After dropping the new file in, regenerate the platform icons:

```
flutter pub run flutter_launcher_icons
```

`splash_logo.png` is optional — `flutter_native_splash.yaml` currently
runs in colour-only mode (Warm Orange) so a missing logo is fine. Drop in
a 512×512 logo here and add `image:` under the `flutter_native_splash`
section of `pubspec.yaml` to get a centred mark on the splash screen.
