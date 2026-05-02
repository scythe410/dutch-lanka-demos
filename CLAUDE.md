# CLAUDE.md

Context for Claude Code working in the Dutch Lanka repo. Read this before making changes. **Also read `docs/progress.md` at the start of every session** to understand current state — it's the running log of what's been built.

## Project overview

Dutch Lanka is a mobile-first bakery ordering and management system for a single bakery in Sri Lanka. Two Flutter apps (customer and manager) talk to a Firebase backend (Auth, Firestore, Storage, FCM, Cloud Functions). PayHere handles payments (LKR, plus local wallets like eZ Cash, mCash, Genie, FriMi). The full architecture is in `docs/architecture.md`. The visual design system is in `docs/design.md`.

The architecture is **serverless / BaaS**: the apps talk to Firebase directly (subject to Security Rules), and any privileged operation goes through Cloud Functions. There is no custom REST server, and one will not be added.

## Repository layout

```
/
├── apps/
│   ├── customer/             # Customer-facing Flutter app
│   └── manager/              # Manager Flutter app
├── functions/                # Firebase Cloud Functions (Node.js + TypeScript)
├── packages/
│   └── shared/               # Shared Dart package: models, theme, widgets, utils
├── firestore.rules
├── storage.rules
├── firestore.indexes.json
├── firebase.json
├── .firebaserc
└── docs/
    ├── architecture.md       # Full system architecture
    └── design.md             # Visual design system
```

Both Flutter apps depend on `packages/shared` for models, theme, and reusable widgets. **Anything that exists in both apps belongs in `shared`.**

## Tech stack

- Flutter 3.x, Dart 3.x
- Riverpod for state management (no `setState` outside trivial local UI state)
- GoRouter for navigation
- Freezed + json_serializable for models
- Firebase: Auth, Firestore, Storage, FCM, App Check, Cloud Functions
- Cloud Functions: Node.js 20, TypeScript (strict), Zod for input validation
- PayHere via `payhere_mobilesdk_flutter`
- Google Maps via `google_maps_flutter`
- Icons via `lucide_icons` (single icon family — do not mix in others)

## Common commands

### Flutter (run inside `apps/customer/` or `apps/manager/`)
```
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
flutter analyze              # must pass before commit
flutter test
flutter build apk  --flavor prod -t lib/main_prod.dart --release
flutter build ipa  --flavor prod -t lib/main_prod.dart --release
```

### Cloud Functions (run inside `functions/`)
```
npm install
npm run build                # tsc
npm run lint                 # eslint
npm run test                 # jest
npm run serve                # functions emulator
firebase deploy --only functions
```

### Firebase
```
firebase emulators:start                  # full suite (Auth, Firestore, Functions, Storage)
firebase use dev | staging | prod         # switch environments
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

## Architectural rules — do not violate

These rules exist for a reason. If a task seems to need breaking one, stop and ask.

1. **All business writes go through Cloud Functions.** Orders, payment status, stock changes, role assignments. The client never writes directly to `/orders/*`, `/products/*` (stock), or sets custom claims. Firestore Rules enforce this — bypassing them means rewriting rules, which is a red flag.

2. **The PayHere success callback is not authoritative.** Only the `payhereNotify` HTTPS Function (after MD5 verification) is allowed to flip an order to `paid`. The app shows "processing payment" and waits for the order doc's `paymentStatus` to update via Firestore listener. Never commit state from a client-side payment callback.

3. **Roles use Auth custom claims, not just Firestore fields.** `role: "customer" | "manager" | "staff"` is a custom claim set by the `setManagerRole` Function. The mirror in `users/{uid}.role` is for UI convenience only. Authorization checks (in Rules and Functions) read the claim.

4. **Real-time UI uses Firestore listeners, not polling.** Use `snapshots()` streams in Flutter. No `Timer.periodic(...)` polling, no pull-to-refresh as a substitute for live updates.

5. **Cart lives in app state, not Firestore.** Until checkout calls `createOrder`, the cart is in a Riverpod provider on the device. Adding it to Firestore would mean a write per "+1 tap" — wasteful and unneeded for a single-device experience.

6. **Never log PII** (phone numbers, full addresses, emails) in Cloud Functions logs. Hash or redact. Cloud Logging is queryable and not appropriate for personal data.

## Coding conventions

### Dart
- File naming: `snake_case.dart`. Class names: `PascalCase`. Provider names: `camelCase`.
- One screen per file in `lib/screens/`. Reusable widgets in `lib/widgets/` (or `packages/shared/lib/widgets/` if used by both apps).
- Models with `freezed` — no plain Dart classes for data shapes that cross the wire.
- Prefer `final`. Avoid `dynamic`. Avoid `late` unless genuinely needed.
- Format with `dart format` (set up as a pre-commit hook).
- Folder layout inside each app:
  ```
  lib/
  ├── main_dev.dart
  ├── main_staging.dart
  ├── main_prod.dart
  ├── app.dart                # Root MaterialApp + theme + router
  ├── routing/                # GoRouter routes & guards
  ├── screens/
  ├── widgets/                # App-specific widgets only
  ├── providers/              # Riverpod providers
  ├── services/               # Wrappers around Firebase, PayHere, Maps
  └── theme/                  # Re-exports from shared/theme
  ```

### TypeScript (Cloud Functions)
- `strict: true` in tsconfig. Treat `any` as a code smell — comment when unavoidable.
- Each function in its own file under `src/functions/`. Re-export from `src/index.ts`.
- Validate every callable/HTTPS input with Zod.
- Use Firestore transactions for any multi-document update (e.g. order create + stock decrement).
- All money in **cents** (LKR cents) as integers — never floats.

### Tests
- Cloud Functions: Jest, mocking Firestore via `firebase-functions-test`. Cover `createOrder`, `payhereNotify` (signature verification, all status codes), and `onOrderCreate` (stock atomicity).
- Flutter: widget tests for shared components in `packages/shared`. Smoke tests for top-level screens. Skip provider tests until logic is non-trivial.

## Theme & design

Full system in `docs/design.md`. Quick reference:

- **Primary:** Warm Orange `#FFA951`
- **Surface:** Soft Cream `#FAF3E1`
- **On-primary:** White `#FFFFFF`
- **Muted:** Silver `#C0C0C0`
- **Text:** Black `#000000`
- **Font:** Work Sans (Regular 400, Medium 500, Semi Bold 600) via `google_fonts`

**Always import colors and text styles from `packages/shared/lib/theme/`.** Do not hardcode hex values or font weights in widgets. If you find yourself reaching for a color not in the palette, stop and ask — adding a color is a design decision, not an implementation one.

## Authentication notes

- **Customer app:** Email + password sign-in. A 4-digit verification code is emailed at signup (Firebase Auth email link or our own `sendVerificationCode` Function — see architecture.md). No SMS, no cost.
- **Manager app:** Email + password only. Manager accounts are provisioned manually via the `setManagerRole` callable Function. There is no public manager signup screen.

## Firebase environments

Three projects: `sugar-studio-dev`, `sugar-studio-staging`, `sugar-studio-prod`. Switch with `firebase use <alias>`. Each Flutter flavor binds to one project via `firebase_options_<flavor>.dart` (generated by `flutterfire configure`).

The Blaze (pay-as-you-go) plan is required from day one because Cloud Functions need to make outbound HTTP calls to PayHere — Spark plan blocks this. Actual cost stays at $0 while usage is below free quotas.

**Never commit:**
- `firebase_options_prod.dart`
- `google-services.json` for prod
- `GoogleService-Info.plist` for prod
- PayHere live merchant secret
- Any service account key

These live in CI secrets and developer-local files (gitignored).

## Common task playbooks

### Add a new screen
1. Match an existing sibling screen for structure (look for the same archetype in `docs/design.md`).
2. Create `lib/screens/<feature>_screen.dart`.
3. Add the route to `lib/routing/router.dart`.
4. Pull from theme — never hardcode colors, paddings, radii.
5. If the screen needs new widgets, decide: app-specific (`lib/widgets/`) or shared (`packages/shared/lib/widgets/`)?

### Add a new Cloud Function
1. Create `functions/src/functions/<name>.ts`.
2. Define a Zod schema for inputs.
3. Implement, with a transaction if writing multiple docs.
4. Re-export from `functions/src/index.ts`.
5. Add a Jest test covering happy path + at least one error case.
6. If it's an HTTPS endpoint, document the contract in a comment at the top of the file.

### Add a new Firestore collection
1. Update `docs/architecture.md` section 5 (data model).
2. Update `firestore.rules` — default deny, then add the minimum read/write the client needs.
3. Update `firestore.indexes.json` if you'll query with multiple `where`s.
4. Add the model to `packages/shared/lib/models/`.

### Change something about payments
Re-read `docs/architecture.md` section 4.3 (payment flow) before editing anything in `apps/*/lib/services/payhere_service.dart` or `functions/src/functions/payhereNotify.ts`. The MD5 verification is non-obvious — get it wrong and you accept fake payments.

## Don'ts

- Don't add a custom REST/Express backend. The serverless design is intentional.
- Don't add new third-party state-management libraries. Riverpod is the choice.
- Don't add a new font, icon set, or color outside the palette.
- Don't bypass the Cloud Function for "performance" reasons on writes.
- Don't use `print` — use the `logger` package.
- Don't use `localStorage`-equivalent persistence for sensitive data. Use `flutter_secure_storage` for tokens.
- Don't introduce hardcoded strings for user-facing text. Use `intl` from day one — Sinhala/Tamil localization is in the roadmap.

## Progress logging

This project is built across many sessions following `docs/prompt_flow.md` (a separate developer-side doc, not for Claude Code to follow directly). Because Claude Code has no memory between sessions, `docs/progress.md` is the project's persistent memory.

Rules:
- **Read `docs/progress.md` at the start of every session.** It tells you where the project is and what's next.
- **Update `docs/progress.md` at the end of every step before stopping.** This is non-negotiable — skipping it means the next session starts blind.
- Move "Current status" forward to reflect the just-completed step and the next one.
- Add a new entry under "Step log" describing what was built, any deviations from the prompt's instructions, and any TODOs left behind.
- Note non-obvious choices in "Decisions" with a one-line rationale (e.g. "chose package X over Y because…").
- Note bugs or hacks in "Known issues".
- Keep entries terse — bullets, not essays. Future sessions will skim, not read.

If `docs/progress.md` doesn't exist yet, the user will prompt you to create it.

## Definition of done

A change is done when:
- `flutter analyze` passes (zero warnings).
- `flutter test` passes.
- `npm run lint` and `npm run test` pass in `functions/`.
- Firestore Rules emulator tests pass for any rule changes.
- The screen / function matches the design doc / architecture doc — no drift.
- Sensitive values are in env / secrets, not committed.
