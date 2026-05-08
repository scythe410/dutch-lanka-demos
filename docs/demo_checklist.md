# Demo readiness checklist

What still needs human hands before the demo runs end-to-end. Ordered so each phase unblocks the next — don't skip ahead. Pair with `runbook.md` (ops reference) and `progress.md` (current state).

---

## Quick command reference

Every command below assumes you're at the **repo root** (`dutch-lanka/`). The `cd …` is shown when needed.

### `.env` files (must exist before any flutter run)

Both `apps/customer/.env` and `apps/manager/.env` need at minimum:

```
GOOGLE_MAPS_API_KEY=<your-android+ios-maps-key>
```

If either file is missing, gradle silently uses an empty key and Maps tiles render blank. (`flutter_dotenv` will throw at runtime.)

### Run the apps

> **Always run with the working directory set to the app**. From the repo root:

Customer app, dev flavor, against **deployed dev** Firebase:
```
cd apps/customer
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

Customer app, dev flavor, against the **local emulator suite** (recommended for the smoke phases below):
```
cd apps/customer
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

Manager app — same shape, just swap the dir:
```
cd apps/manager
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

Prod release build (only after icons + secrets are in place):
```
cd apps/customer        # or apps/manager
flutter run --flavor prod -t lib/main_prod.dart --release
```

### Static checks

```
# from each of apps/customer, apps/manager, packages/shared
flutter analyze
flutter test
```

```
# from functions/
npm run lint
npm run build
npm test                # rules tests only
npm run test:functions  # full integration suite (35 cases, runs the firestore emulator)
```

### `flutter run` is failing — first three things to check

1. **`flutter pub get` not run after a pubspec change.** The CI you saw clean used the freshly-resolved dep graph. Run it again from the app dir.
2. **iOS scheme not set up.** `flutter run --flavor dev` on iOS needs an Xcode scheme literally named `dev`. Setup is **manual** in Xcode — follow `docs/ios_flavors_setup.md` end-to-end (one-time per app). Until that's done, run on Android only.
3. **Missing google-services.json for the flavor.** `apps/<app>/android/app/src/dev/google-services.json` and `apps/<app>/android/app/src/prod/google-services.json` must both exist. If `flutterfire configure` was only run for one flavor, only that one works. Re-run with the other project.

If you paste the actual error message I can pinpoint which of the three (or something else) it is.

---

## Phase 1 — Firebase Console & API setup

These are one-time toggles per project. Repeat for both `dutch-lanka-dev` and `dutch-lanka-prod` unless noted.

### Authentication
- [ ] Email/password provider enabled (Console → Authentication → Sign-in method)
- [ ] At least one **dev** test customer account created (Console → Users → Add)

### App Check
- [ ] App Check **registered** for each app (Console → App Check → Apps): Android via Play Integrity, iOS via DeviceCheck
- [ ] App Check **enforcement enabled** per API: Firestore, Storage, Cloud Functions (Console → App Check → APIs → "Enforce")
- [ ] Debug token whitelisted for every dev device: launch the dev build once, copy the UUID printed to logcat / Xcode console, paste into Console → App Check → Apps → "Manage debug tokens" (see runbook §7)

### Cloud Functions
- [ ] Region pinned to `asia-south1` (already set in code — verify deploy lands there)
- [ ] PayHere secrets set on the dev project:
  ```
  firebase functions:config:set \
    payhere.merchant_id="<sandbox_id>" \
    payhere.merchant_secret="<sandbox_secret>" \
    --project dutch-lanka-dev
  ```
- [ ] Repeat for prod with **live** PayHere credentials. Don't paste the live secret into shell history — pipe from your password manager:
  ```
  firebase functions:config:set \
    payhere.merchant_id="$LIVE_MERCHANT_ID" \
    payhere.merchant_secret="$LIVE_MERCHANT_SECRET" \
    --project dutch-lanka-prod
  ```
- [ ] Verify what's set:
  ```
  firebase functions:config:get --project dutch-lanka-dev
  ```
- [ ] Functions deployed:
  ```
  cd functions
  npm install
  npm run build
  firebase deploy --only functions --project dutch-lanka-dev
  ```

### Crashlytics
- [ ] Console → Crashlytics → "Get started" clicked once per app to create the dashboard
- [ ] (Android, release builds with R8) Wire Crashlytics mapping upload in `app/build.gradle.kts` `firebaseCrashlytics { ... }` once proguard is on
- [ ] (iOS) confirm Run Script phase for dSYM upload exists in `ios/Runner.xcodeproj` (re-run `flutterfire configure` if missing)

### Performance Monitoring
- [ ] Console → Performance → "Get started" clicked once per app

### Cloud Messaging (FCM)
- [ ] Android: `google-services.json` present in `apps/<app>/android/app/` for both dev and prod (gitignored for prod — fetch from secrets)
- [ ] iOS: APNs auth key uploaded to Console → Project settings → Cloud Messaging
- [ ] Test push from Console → Cloud Messaging → "Send test message" using a real device's FCM token (read it from Firestore `users/{uid}.fcmTokens` after first login)

### Google Maps
- [ ] Maps SDK for Android **and** Maps SDK for iOS enabled in GCP Console for each project
- [ ] Dev key added to `apps/customer/.env` and `apps/manager/.env` as `GOOGLE_MAPS_API_KEY=...`
- [ ] Restrict the prod key to the app bundle IDs (`lk.dutchlanka.dutch_lanka_customer`, `lk.dutchlanka.dutch_lanka_manager`) before going live

### Branding
- [ ] Replace `apps/customer/assets/branding/app_icon.png` and `apps/manager/assets/branding/app_icon.png` with the real bakery wordmark (1024×1024)
- [ ] Regenerate platform icons + splash for each app:
  ```
  cd apps/customer
  flutter pub get
  flutter pub run flutter_launcher_icons
  flutter pub run flutter_native_splash:create

  cd ../manager
  flutter pub get
  flutter pub run flutter_launcher_icons
  flutter pub run flutter_native_splash:create
  ```
- [ ] Rebuild + confirm icons + splash on a device:
  ```
  cd apps/customer
  flutter clean
  flutter run --flavor dev -t lib/main_dev.dart
  ```

---

## Phase 2 — Local emulator smoke

Catch all the boring breakage before involving a phone. **Three terminals**: emulators, seeder, app.

**Terminal A — emulator suite** (leave running):
```
firebase use dev
firebase emulators:start --project dutch-lanka-dev
```
Ports: Auth :9099, Firestore :8080, Functions :5001, Storage :9199, UI :4000.

**Terminal B — seed + tests**:
```
cd functions
npm install              # only needed once or after package.json changes
npm run seed
```

- [ ] Open `http://localhost:4000` → Firestore tab shows **10 products** and **2 users**

Then run the static checks (still in `functions/`):
```
npm run lint
npm run build
npm test                 # rules tests
npm run test:functions   # 35-case integration suite
```

- [ ] `npm run lint` clean
- [ ] `npm test` — rules tests pass
- [ ] `npm run test:functions` — 35/35 pass

**Terminal C — app pointed at emulator** (pick one app to start):
```
cd apps/customer
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

- [ ] Customer app launches and `flutter logs` shows: `Firebase: connected to emulators at <host>` followed by `Firebase initialized [dev]: dutch-lanka-dev`

---

## Phase 3 — PayHere sandbox wiring

- [ ] Sandbox merchant account created at https://sandbox.payhere.lk
- [ ] Sandbox merchant ID + secret set (commands in Phase 1 → Cloud Functions)
- [ ] Functions deployed to dev with the secrets baked in:
  ```
  cd functions
  firebase deploy --only functions --project dutch-lanka-dev
  ```
- [ ] Expose the local Functions emulator with ngrok (in a fourth terminal — keep emulators + app running):
  ```
  ngrok http 5001
  ```
  Copy the HTTPS forwarding URL it prints (e.g. `https://abc123.ngrok-free.app`).
- [ ] In the PayHere sandbox merchant console, set `notify_url` to:
  ```
  https://<ngrok-id>.ngrok-free.app/dutch-lanka-dev/asia-south1/payhereNotify
  ```
  (When using deployed dev functions instead of the emulator, use:
  `https://asia-south1-dutch-lanka-dev.cloudfunctions.net/payhereNotify`)

**Verify** — keep the emulator + customer app from Phase 2 running:
- [ ] Place an order from the customer app
- [ ] PayHere sandbox sheet opens — pay with `4916217501611292`, any future expiry, CVV `123`
- [ ] In the Firestore emulator UI (`http://localhost:4000`), the order doc flips `paymentStatus: paid` within ~5s
- [ ] Customer "processing payment" screen advances to the tracking screen
- [ ] Each ordered product's `stock` has **decremented** in the emulator UI

If the order stays `pending` for >30s, your `notify_url` isn't reaching the emulator — re-check the ngrok URL and tail the Functions logs:
```
# in Terminal A (emulators) — payhereNotify logs print there
# OR for deployed functions:
firebase functions:log --only payhereNotify --project dutch-lanka-dev
```

---

## Phase 4 — Real-time + driver flow (emulator + device)

Now spin up the manager app alongside the customer — keep the emulator suite from Phase 2 running.

**Terminal D — manager app**:
```
cd apps/manager
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

- [ ] Place an order from the customer app
- [ ] In the Firestore emulator UI (`http://localhost:4000` → Firestore → `orders/<id>`), manually edit the `status` field: `paid → preparing → dispatched`
- [ ] Customer tracking screen reflects each transition within ~1 second (Firestore listener, not poll)
- [ ] In the manager app, open the order, toggle **driver mode** on
- [ ] On the customer's tracking screen, the courier marker appears and moves on the map as the manager device's location updates

---

## Phase 5 — Customer app device walkthrough

Use a **real Android device**. iOS simulators don't deliver pushes — any push test must be on a real iPhone. This phase runs against the **deployed dev** Firebase project (so pushes route via real FCM, not the emulator).

```
cd apps/customer
flutter devices                      # confirm your device shows up
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```
(Drop `--dart-define=USE_EMULATOR=true` here on purpose.)

- [ ] Onboarding → signup → email verification → home
- [ ] Edit profile (name, phone, photo upload)
- [ ] Add a delivery address with the map picker
- [ ] Browse products → add to cart → checkout using the new address
- [ ] Pay via PayHere sandbox (test card `4916217501611292`)
- [ ] Watch the order ride through preparing → dispatched → delivered
- [ ] After delivery, leave a review on a delivered order
- [ ] Confirm an FCM push lands on the device for each status change

To watch logs from the device:
```
flutter logs            # while flutter run is attached
# or
adb logcat | grep -i flutter      # Android, separate terminal
```

---

## Phase 6 — Manager bootstrap + console walkthrough

### 6a. Bootstrap on the **emulator** (fastest, recommended for first run)

- [ ] Start the emulator suite (Terminal A from Phase 2)
- [ ] Open `http://localhost:4000` → Authentication → Add user → e.g. `owner@dutchlanka.test` / `password123`. Copy the generated UID.
- [ ] In a fresh terminal:
  ```
  cd functions
  npm run shell
  ```
- [ ] At the `firebase >` prompt, paste:
  ```
  setManagerRole({targetUid: '<paste-uid>', role: 'manager'}, {auth: {uid: 'bootstrap', token: {role: 'manager'}}})
  ```
- [ ] Sign into the manager app (Terminal D from Phase 4) as that user — should land on `/dashboard`

### 6b. Bootstrap on the **deployed dev** project (when you need pushes on a real device)

- [ ] Firebase Console → Authentication → Users → Add user
- [ ] Promote them with a one-shot admin script (the in-app shell trick only works on the emulator). Quickest path:
  ```
  cd functions
  npx tsx -e "
    import * as admin from 'firebase-admin';
    admin.initializeApp({projectId: 'dutch-lanka-dev'});
    admin.auth().setCustomUserClaims('<uid>', {role: 'manager'})
      .then(() => admin.firestore().doc('users/<uid>').set({role: 'manager', uid: '<uid>'}, {merge: true}))
      .then(() => process.exit(0));
  "
  ```
  (Requires `GOOGLE_APPLICATION_CREDENTIALS` pointing at a service-account key for `dutch-lanka-dev`.)
- [ ] Sign in on the manager device

### 6c. Walkthrough

- [ ] From the customer app on a second device, place an order
- [ ] The manager dashboard shows the order **in real time** (no refresh)
- [ ] Walk it through `paid → preparing → dispatched → delivered` from the manager and watch the customer device react in real time
- [ ] Add a new product from the manager → it appears in the customer app's home immediately
- [ ] Trigger a low-stock alert (drop a product's `stock` below threshold from the manager UI) → manager device gets a push, the alert appears under Inventory
- [ ] Submit a complaint from the customer app → manager More → Complaints sees it live, "Mark resolved" works

---

## Phase 7 — Crashlytics + Performance verification

Crashlytics is disabled in `kDebugMode`, so you must run `--release` (or `--profile`) to see anything reach the dashboard.

```
cd apps/customer
flutter run --flavor prod -t lib/main_prod.dart --release
```

- [ ] Trigger a test crash. Quickest path is to temporarily add a hidden button that calls `FirebaseCrashlytics.instance.crash();`, build, tap it, then **remove the button before the next build**. Or use Dart DevTools (`Run → Open DevTools` while attached) to invoke it from the console.
- [ ] **Re-launch the app** — Crashlytics flushes on the *next* run, not the crashing one
- [ ] Within ~5 min the issue appears in Console → Crashlytics → Issues for the matching app
- [ ] Repeat on iOS (real device, not simulator):
  ```
  cd apps/customer
  flutter run --flavor prod -t lib/main_prod.dart --release -d <ios-device-id>
  ```
- [ ] Console → Performance shows network calls + screen-render traces after ~30 min of normal use (auto-traces; no manual instrumentation yet)

---

## Phase 8 — Final dry-run

For the actual demo run **against deployed dev** (not the local emulator). Stop emulators first:
```
# Ctrl-C the firebase emulators:start terminal
```

Build + install the dev flavor on both demo devices:
```
cd apps/customer
flutter run --flavor dev -t lib/main_dev.dart -d <customer-device>

cd ../manager
flutter run --flavor dev -t lib/main_dev.dart -d <manager-device>
```
(No `--dart-define=USE_EMULATOR=true` — you want the deployed backend.)

- [ ] Run the **full happy path** on a real Android device (customer side): onboarding → signup → browse → cart → pay (sandbox) → track → delivered → review
- [ ] Repeat the **full manager flow** on the manager-side device: receive the order → progress through statuses → toggle driver mode → mark delivered
- [ ] Anything that feels janky — note it down with steps to reproduce. That's the punch list for the next round.
- [ ] Charge both demo devices to 100%, install the dev build of each app, double-check the emulator suite is **not** running (you want the deployed dev backend, not localhost) for the actual demo

---

## Pre-demo "is it actually presentable" checklist

- [ ] Both apps installed on demo devices, latest dev build, signed in to known test accounts
- [ ] Test customer + test manager already exist in the dev project
- [ ] At least one paid order exists in `preparing` status so the dashboard isn't empty on first show
- [ ] At least one low-stock alert exists so the alert tile is non-zero
- [ ] At least one delivered order with a review so the manager Reports charts have data
- [ ] Wifi or hotspot reachable; PayHere sandbox is reachable from the phone's network
- [ ] App Check debug tokens whitelisted for the demo devices (otherwise enforcement will silently kill every Firestore call)
- [ ] Firebase Console open in a tab as a fallback "look, it's real" prop
