# Demo readiness checklist

What still needs human hands before the demo runs end-to-end. Ordered so each phase unblocks the next — don't skip ahead. Pair with `runbook.md` (ops reference) and `progress.md` (current state).

Status legend: `[x]` confirmed working in the current session, `[ ]` pending, `[~]` deferred (intentionally not part of this demo). Items still pending generally need either a real device, the Firebase Console, or a credential the emulator can't fake.

**Maps is deferred for this demo.** The address picker on the customer checkout screen, the courier marker on the order-tracking screen, and the manager's order-detail map preview all use `google_maps_flutter` — they will render as a grey box. The order flow itself (browse → cart → checkout → pay → status updates → delivery) does not depend on Maps. When the demo is over, see the "Wiring Maps later" section at the bottom of this file.

---

## Quick command reference

Every command below assumes you're at the **repo root** (`dutch-lanka/`). The `cd …` is shown when needed.

### `.env` files

Both `apps/customer/.env` and `apps/manager/.env` need at minimum:

```
GOOGLE_MAPS_API_KEY=AIza...your-android+ios-maps-key
```

> **Gotcha learned the hard way:** gradle reads `.env` at *build* time and bakes the Maps key into `AndroidManifest.xml`. After editing `.env` you need a full rebuild — `flutter clean` + `flutter run`. Hot reload and hot restart only swap Dart code; the manifest still has whatever key was there last build.

`functions/.env.local` and `functions/.env.dutch-lanka-dev` (both gitignored) hold:
```
PAYHERE_MERCHANT_ID=...
PAYHERE_NOTIFY_URL=http://localhost:5001/dutch-lanka-dev/asia-south1/payhereNotify
```

`functions/.secret.local` (also gitignored) holds:
```
PAYHERE_MERCHANT_SECRET=...
```

The Functions emulator auto-loads all three on `firebase emulators:start` and the prompts go away.

### Run the apps

> **Always run with the working directory set to the app**.

Customer / manager, dev flavor, against the **local emulator suite**:
```
cd apps/customer        # or apps/manager
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

Same against **deployed dev** Firebase (drop the `--dart-define`):
```
cd apps/customer
flutter run --flavor dev -t lib/main_dev.dart
```

Prod release build (only after icons + secrets are in place):
```
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

### Things that bite during first-time setup

1. **`flutter pub get` not run after a pubspec change.** Run it again from the app dir.
2. **iOS scheme not set up.** `flutter run --flavor dev` on iOS needs a manually-created Xcode scheme called `dev`. Follow `docs/ios_flavors_setup.md` end-to-end. Until that's done, run on Android only.
3. **Missing `google-services.json` for the flavor.** `apps/<app>/android/app/src/dev/google-services.json` and `apps/<app>/android/app/src/prod/google-services.json` must both exist. Re-run `flutterfire configure` for the missing flavor.
4. **`flutter_local_notifications` AAR metadata error.** Already fixed — `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.0.4` are in both apps' `build.gradle.kts`.
5. **"Cleartext HTTP traffic to 10.0.2.2 not permitted".** Already fixed — debug-only `network_security_config.xml` whitelists the emulator hosts.
6. **Corrupted Gradle cache** (`Could not read workspace metadata from … kotlin-dsl/accessors/.../metadata.bin`). Stop daemons, wipe the cache, retry:
   ```
   cd apps/<app>/android && ./gradlew --stop
   rm -rf ~/.gradle/caches/8.14 apps/<app>/android/.gradle apps/<app>/build
   cd apps/<app> && flutter clean && flutter pub get
   ```
7. **First Maven download timing out** ("Read timed out", "Remote host terminated the handshake"). Already mitigated — `gradle.properties` sets HTTP timeouts to 5 min.

---

## Phase 1 — Firebase Console & API setup

One-time toggles per project. Repeat for both `dutch-lanka-dev` and `dutch-lanka-prod` unless noted.

### Authentication
- [x] Email/password provider enabled in Console → Authentication → Sign-in method (deployed dev)
- [x] Demo customer + manager accounts seeded into the local emulator (`npm run seed` creates them)
- [x] Same demo accounts seeded into **deployed** dev Firestore + Auth via `ALLOW_DEPLOYED_SEED=1 GOOGLE_APPLICATION_CREDENTIALS=... GCLOUD_PROJECT=dutch-lanka-dev npx tsx tools/seed.ts`

### App Check
- [ ] App Check **registered** for each app (Console → App Check → Apps): Android via Play Integrity, iOS via DeviceCheck
- [ ] App Check **enforcement enabled** per API: Firestore, Storage, Cloud Functions (Console → App Check → APIs → "Enforce") — keep this **off** while testing on the AVD; it'll silently kill every Firestore call. Flip on at deploy day.
- [ ] Debug token whitelisted for every dev device: launch the dev build once, copy the UUID printed to logcat (`Enter this debug secret into the allow list...`), paste into Console → App Check → Apps → "Manage debug tokens"

### Cloud Functions config

The handlers use `defineString` / `defineSecret` from `firebase-functions/params` — they read from `functions/.env*` and `functions/.secret.local` files, **not** the legacy `firebase functions:config:set` API.

- [x] `functions/.env.local` and `functions/.env.dutch-lanka-dev` written with `PAYHERE_MERCHANT_ID` + `PAYHERE_NOTIFY_URL` (both gitignored)
- [x] `functions/.secret.local` written with `PAYHERE_MERCHANT_SECRET` (gitignored)
- [x] `PAYHERE_MERCHANT_SECRET` set in **Secret Manager** for deployed dev via `firebase functions:secrets:set PAYHERE_MERCHANT_SECRET --project dutch-lanka-dev` (currently a placeholder)
- [ ] **Real** sandbox merchant ID + secret pasted into the local files + Secret Manager (currently placeholder — won't pass MD5 verification against PayHere). Get them from your PayHere sandbox dashboard.
- [ ] Update `PAYHERE_NOTIFY_URL` in `functions/.env.dutch-lanka-dev` from `http://localhost:5001/...` to `https://asia-south1-dutch-lanka-dev.cloudfunctions.net/payhereNotify` for deployed checkout flow
- [ ] For prod: write `functions/.env.dutch-lanka-prod` with the live values + `firebase functions:secrets:set PAYHERE_MERCHANT_SECRET --project dutch-lanka-prod`
- [x] Functions deployed to dev: all 5 (`createOrder`, `payhereNotify`, `onOrderCreate`, `onOrderStatusChange`, `setManagerRole`) live in `asia-south1`. Deploy URL for `payhereNotify`: `https://asia-south1-dutch-lanka-dev.cloudfunctions.net/payhereNotify`

### Crashlytics
- [ ] Console → Crashlytics → "Get started" clicked once per app
- [ ] (Android, release builds with R8) Wire mapping upload in `app/build.gradle.kts` `firebaseCrashlytics { ... }` once proguard is on
- [ ] (iOS) confirm Run Script phase for dSYM upload exists in `ios/Runner.xcodeproj`

### Performance Monitoring
- [ ] Console → Performance → "Get started" clicked once per app

### Cloud Messaging (FCM)
- [x] Android: dev `google-services.json` present in both apps (committed)
- [ ] Android prod: `google-services.json` for prod project (gitignored — fetch from secrets store)
- [ ] iOS: APNs auth key uploaded to Console → Project settings → Cloud Messaging
- [ ] Test push from Console → Cloud Messaging → "Send test message" using a real device's FCM token (registers via `arrayUnion` to `users/{uid}.fcmTokens` after first login)

### Google Maps — DEFERRED
- [~] Map widgets will render as a grey tile in the demo. Acceptable: address picker still accepts tap coordinates, order tracking still shows status text, driver mode still updates Firestore. See "Wiring Maps later" at the bottom of this file when ready to plug it in properly.

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

---

## Phase 2 — Local emulator smoke

**Three terminals**: emulators, seeder + tests, app.

**Terminal A — emulator suite** (leave running):
```
firebase use dev
firebase emulators:start --project dutch-lanka-dev
```
Ports: Auth :9099, Firestore :8080, Functions :5001, Storage :9199, UI :4000.

- [x] Emulator suite boots cleanly without env prompts (`functions: Loaded environment variables from .env.dutch-lanka-dev, .env.local`)

**Terminal B — seed + tests**:
```
cd functions
npm install
npm run seed
```

- [x] `http://localhost:4000` → Firestore tab shows **10 products** and **2 users** (`customer@dutchlanka.test`, `manager@dutchlanka.test`, both with password `password123`)

Then run the static checks (still in `functions/`):
```
npm run lint
npm run build
npm test
npm run test:functions
```

- [x] `npm run lint` clean
- [x] `npm run test:functions` — 35/35 pass
- [ ] `npm test` — rules tests pass (skipped this run; run before deploy)

**Terminal C — customer app pointed at emulator**:
```
cd apps/customer
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

- [x] App launches and logs `Firebase: connected to emulators at 10.0.2.2` followed by `Firebase initialized [dev]: dutch-lanka-dev`
- [x] Sign in with `customer@dutchlanka.test` / `password123` reaches the home grid
- [x] Product grid renders 10 seeded products without overflow stripes (after `childAspectRatio: 0.58` fix)

---

## Phase 3 — Customer Tier-1 walkthrough (no payment yet)

- [x] Tap product → detail panel opens, quantity stepper works, "Add to cart"
- [x] Cart icon → cart screen lists items with totals + Checkout button visible
- [ ] Checkout button → checkout screen renders address picker + order summary
- [ ] Profile icon → profile screen, six menu rows
- [ ] Profile → Edit Profile → name, phone, photo upload
- [ ] Profile → Shipping Addresses → "Add address" sheet renders. Map will be grey (Maps deferred); tap-to-pin still records lat/lng coordinates.
- [ ] Profile → Change Password → reauth + new password
- [ ] Profile → Orders (empty until first paid order)
- [ ] Profile → Settings → notification toggles, language, sign-out
- [ ] Profile → About + Contact → static stubs

---

## Phase 4 — PayHere sandbox wiring (Tier 2)

- [ ] Sandbox merchant account created at https://sandbox.payhere.lk
- [ ] Real sandbox merchant ID + secret pasted into `functions/.env.local` and `functions/.secret.local`
- [ ] Restart `firebase emulators:start` so it picks up the updated values
- [ ] Expose the local Functions emulator with ngrok (in a fourth terminal):
  ```
  ngrok http 5001
  ```
- [ ] Update `PAYHERE_NOTIFY_URL` in `functions/.env.local` to:
  ```
  PAYHERE_NOTIFY_URL=https://<ngrok-id>.ngrok-free.app/dutch-lanka-dev/asia-south1/payhereNotify
  ```
- [ ] Restart emulators again
- [ ] In the PayHere sandbox merchant console, set `notify_url` to the same URL

**Verify**:
- [ ] Place an order from the customer app
- [ ] PayHere sandbox sheet opens — pay with `4916217501611292`, any future expiry, CVV `123`
- [ ] Order doc in the Firestore emulator UI flips `paymentStatus: paid` within ~5s
- [ ] Customer "processing payment" screen advances to the tracking screen
- [ ] Each ordered product's `stock` has decremented in the emulator UI

If the order stays `pending` for >30s, your `notify_url` isn't reaching the emulator — re-check the ngrok URL and tail the Functions logs in Terminal A.

---

## Phase 5 — Real-time + driver flow (Tier 3, both apps simultaneously)

Keep customer app + emulator suite running.

**Terminal D — manager app**:
```
cd apps/manager
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```

- [x] Manager app boots and signs in with `manager@dutchlanka.test` / `password123`, lands on `/dashboard`
- [x] Dashboard renders today's-sales / active-orders / low-stock KPIs
- [x] Manager app sees the seeded products in the Products tab
- [ ] Place an order from the customer app → manager dashboard shows it within ~1 s (live Firestore listener)
- [ ] Manually flip `status` in the Firestore emulator UI: `paid → preparing → dispatched`. Customer tracking reflects each transition within ~1 s.
- [ ] In the manager app, open the order, toggle **driver mode** on
- [~] Courier marker on the customer's map — Maps deferred; the marker won't render but the manager still pings location to Firestore (you can verify in the emulator UI: `/orders/{id}/courier_pings/`)

---

## Phase 6 — Manager promotions

The seeded `manager@dutchlanka.test` already has the `manager` role claim from `npm run seed`. Use these flows when you need to promote an *additional* user.

### 6a. Emulator (fastest)
- [ ] Create user via the emulator UI → Authentication → Add user
- [ ] In a fresh terminal: `cd functions && npm run shell`
- [ ] At the `firebase >` prompt:
  ```
  setManagerRole({targetUid: '<paste-uid>', role: 'manager'}, {auth: {uid: 'bootstrap', token: {role: 'manager'}}})
  ```

### 6b. Deployed dev (when you need pushes on a real device)
- [ ] Firebase Console → Authentication → Users → Add user
- [ ] Promote with a one-shot admin script:
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
  Requires `GOOGLE_APPLICATION_CREDENTIALS` pointing at a service-account key for `dutch-lanka-dev`.

---

## Phase 7 — Real-device end-to-end (deployed dev backend)

iOS simulators don't deliver pushes — use a **real Android device** for push verification, real iPhone if you also want iOS coverage.

Two ways to get the apps onto a phone:

**A. Attached `flutter run`** (interactive, hot reload, app uninstalls when you Ctrl-C):
```
flutter devices
cd apps/customer
flutter run --flavor dev -t lib/main_dev.dart -d <android-device-id>
```

**B. Build + install standalone APK** (icon stays on the phone, works after unplugging):
```
cd apps/customer
flutter clean
flutter build apk --flavor dev -t lib/main_dev.dart --debug
~/Library/Android/sdk/platform-tools/adb -d install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```
Repeat for `apps/manager`. **No `--dart-define=USE_EMULATOR=true`** — without the flag, the apps talk to deployed Firebase, no laptop needed.

- [x] Both APKs installed on Pixel 9 standalone, talking to deployed dev backend
- [x] Sign-in with seeded credentials works (`customer@dutchlanka.test` / `password123`)
- [x] Browse products against deployed Firestore
- [ ] Edit profile, add address (map will be grey — Maps deferred), place order
- [ ] Pay sandbox card (skipped — `PAYHERE_MERCHANT_SECRET` is still a placeholder)
- [ ] Ride preparing → dispatched → delivered, leave review
- [ ] FCM push lands on the device for each status change (Android works; iOS needs APNs key)

---

## Phase 8 — Crashlytics + Performance verification

Crashlytics is disabled in `kDebugMode`, so you must run `--release` (or `--profile`):

```
cd apps/customer
flutter run --flavor prod -t lib/main_prod.dart --release
```

- [ ] Trigger a test crash via Dart DevTools console (`FirebaseCrashlytics.instance.crash();`) or a temporary debug button (remove before next build)
- [ ] **Re-launch** the app — Crashlytics flushes on the *next* run
- [ ] Within ~5 min the issue appears in Console → Crashlytics → Issues
- [ ] Repeat on iOS (real device, not simulator)
- [ ] Console → Performance shows network + screen-render traces after ~30 min of normal use

---

## Pre-demo "is it actually presentable" checklist

- [ ] Both apps installed on demo devices, latest dev build, signed in to known test accounts
- [ ] Test customer + test manager exist in the dev project (deployed, not just emulator)
- [ ] At least one paid order in `preparing` status so the dashboard isn't empty
- [ ] At least one low-stock alert so the alert tile is non-zero
- [ ] At least one delivered order with a review so the manager Reports charts have data
- [ ] Wifi or hotspot reachable; PayHere sandbox is reachable from the phone's network
- [ ] App Check debug tokens whitelisted for the demo devices
- [ ] Firebase Console open in a tab as a fallback "look, it's real" prop
- [ ] Devices charged; emulator suite **not** running on the laptop (you want the deployed backend)

---

## Wiring Maps later (when this comes back on the agenda)

1. **Delete the previously-leaked key** if you haven't already (GCP Console → APIs & Services → Credentials → ⋮ → Delete). Don't reuse it.
2. **Create a new restricted key** from scratch:
   - **Application restrictions**: "Android apps" with two entries — package `lk.dutchlanka.dutch_lanka_customer.dev` + debug SHA-1, and `lk.dutchlanka.dutch_lanka_manager.dev` + debug SHA-1. Add the prod package IDs (no `.dev` suffix) when you ship.
   - **API restrictions**: only "Maps SDK for Android". Add "Maps SDK for iOS" when iOS comes online.
3. **Get the debug SHA-1** with:
   ```
   cd apps/customer/android && ./gradlew signingReport | grep -A2 "Variant: devDebug" | grep SHA1
   ```
4. **Confirm GCP project has billing linked** (Maps SDK rejects every request without billing, even free-tier traffic). GCP Console → Billing → Link billing account.
5. **Confirm Maps SDK for Android is enabled** for the project (Library → Maps SDK for Android → Enable).
6. Paste the new key into `apps/customer/.env` and `apps/manager/.env` as `GOOGLE_MAPS_API_KEY=AIza...`.
7. **Full rebuild** — `flutter clean && flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true`. Hot reload doesn't re-bake gradle's manifest placeholders.
8. Tiles should render within a few seconds. If they don't, the log line `urls for epoch -1 not available` is the SDK saying "auth refused" — re-check restrictions, billing, or which APIs are enabled.
