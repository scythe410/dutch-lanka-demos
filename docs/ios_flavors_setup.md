# iOS flavor setup — manual Xcode steps

Step 2 of the build wired up Android flavors and Firebase via `flutterfire configure --platforms=android`. iOS was deferred because it requires interactive Xcode work that can't be scripted from the CLI. Do these steps **once per app** when you're ready to build for iOS.

There are two apps to configure: `apps/customer` and `apps/manager`. The steps are identical — substitute the app name and bundle IDs.

## 1. Create build configurations

Open the workspace in Xcode:

```
open apps/customer/ios/Runner.xcworkspace
```

In the project navigator, select **Runner** (the blue icon at the top), then the **Runner project** (not the target) in the editor pane. Go to the **Info** tab.

Under **Configurations**, you should see `Debug`, `Release`, `Profile`. For each one, click the `+` and choose **Duplicate "<name>" Configuration**. Rename the duplicates so you end up with six configurations total:

- `Debug-dev`, `Release-dev`, `Profile-dev`
- `Debug-prod`, `Release-prod`, `Profile-prod`

Delete the original `Debug`, `Release`, `Profile` (Xcode will warn that some schemes reference them — that's fine, we'll fix the schemes next).

## 2. Create schemes

**Product → Scheme → Manage Schemes…**

Duplicate the existing `Runner` scheme twice. Rename to `dev` and `prod`.

For each scheme, click **Edit…** and set:

| Action | Build Configuration |
|---|---|
| Run | `Debug-<flavor>` |
| Test | `Debug-<flavor>` |
| Profile | `Profile-<flavor>` |
| Analyze | `Debug-<flavor>` |
| Archive | `Release-<flavor>` |

Tick **Shared** at the bottom of the Manage Schemes dialog so the scheme files commit to git (`ios/Runner.xcodeproj/xcshareddata/xcschemes/`).

Delete the original `Runner` scheme.

## 3. Set per-configuration bundle IDs

Select the **Runner target** → **Build Settings** → search for `PRODUCT_BUNDLE_IDENTIFIER`. Expand the row to show per-configuration values:

For `apps/customer`:

| Configuration | Bundle ID |
|---|---|
| `Debug-dev` / `Release-dev` / `Profile-dev` | `lk.dutchlanka.dutchLankaCustomer.dev` |
| `Debug-prod` / `Release-prod` / `Profile-prod` | `lk.dutchlanka.dutchLankaCustomer` |

For `apps/manager`, replace `Customer` with `Manager`.

## 4. Run flutterfire configure for iOS

With the build configurations and schemes in place, run from `apps/customer/`:

```
flutterfire configure \
  --project=dutch-lanka-dev \
  --platforms=ios \
  --ios-bundle-id=lk.dutchlanka.dutchLankaCustomer.dev \
  --ios-build-config=Debug-dev \
  --ios-out=ios/Firebase/dev/GoogleService-Info.plist \
  --out=lib/firebase/firebase_options_dev.dart \
  --yes
```

Then for prod:

```
flutterfire configure \
  --project=dutch-lanka-prod \
  --platforms=ios \
  --ios-bundle-id=lk.dutchlanka.dutchLankaCustomer \
  --ios-build-config=Debug-prod \
  --ios-out=ios/Firebase/prod/GoogleService-Info.plist \
  --out=lib/firebase/firebase_options_prod.dart \
  --yes
```

Repeat the two calls inside `apps/manager/` with the manager bundle IDs.

flutterfire will:
- Register the iOS app in each Firebase project.
- Write `GoogleService-Info.plist` to `ios/Firebase/<env>/`.
- Add a Run Script build phase to the Runner target that copies the right plist into the app bundle based on the active configuration.
- Merge the iOS options into the existing `firebase_options_<env>.dart` files.

## 5. Tell Flutter which scheme to use

When running on iOS:

```
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Flutter matches the `--flavor` argument to the Xcode scheme name. Since we named the schemes `dev` and `prod`, the existing commands work as-is.

## 6. Verify

```
flutter run --flavor dev -t lib/main_dev.dart
```

Look for the log line:

```
flutter: Firebase initialized [dev]: dutch-lanka-dev
```

If you see that, iOS is wired up correctly.

## Common pitfalls

- **Scheme name must match `--flavor` exactly** (case-sensitive). `Dev` ≠ `dev`.
- **Bundle ID in Firebase must match the build's `PRODUCT_BUNDLE_IDENTIFIER` exactly.** A mismatch causes `Firebase.initializeApp` to throw `FirebaseException: No app found`.
- **The Run Script phase** flutterfire adds must be **before** "Embed Frameworks" in the build phases list. Drag it up if needed.
- **`Pods` project also has the configurations** — Xcode usually auto-creates them when you add new ones to Runner, but if pod install complains, run `pod install` from `ios/` after each Podfile-touching change.
