# Dutch Lanka — progress log

A running log of completed work, decisions, deviations, and known issues. **Read this at the start of every new session before doing anything else.** It is the canonical source of "where we are" — the docs describe the target, this file describes the present.

When you finish a step, add a new subsection under "Step log" and update "Current status".

---

## Current status

- **Last completed:** Step 1 — monorepo scaffold.
- **Next:** Step 2 (per `docs/prompt_flow.md`, which does not yet exist — the user drives steps via prompt).

---

## Step log

### Step 1 — Monorepo scaffold (2026-05-03)

Goal: stand up the directory layout from `CLAUDE.md` "Repository layout" so that both Flutter apps build the default counter app and Cloud Functions compile clean. No feature code, no flavors, no Firebase config files yet.

**What was built:**

- `apps/customer/` — `flutter create --org lk.dutchlanka --project-name dutch_lanka_customer --platforms=android,ios`. Flutter 3.41.9, Dart 3.11.5. Default counter app. `flutter analyze` clean.
- `apps/manager/` — same flags, project name `dutch_lanka_manager`. `flutter analyze` clean.
- `packages/shared/` — `flutter create --template=package --project-name dutch_lanka_shared`. Empty package, default scaffold. `flutter analyze` clean.
- `functions/` — TypeScript + ESLint scaffold matching what `firebase init functions` produces:
  - `package.json` with scripts (`build`, `lint`, `serve`, `test`, etc.), Node 20 engine.
  - Deps: `firebase-admin ^12.6.0`, `firebase-functions ^6.0.1`. Dev deps: `typescript ^5.4.5`, `eslint ^8.57.0`, `@typescript-eslint/*`, `eslint-config-google`, `firebase-functions-test`.
  - `tsconfig.json` (strict mode), `tsconfig.dev.json`, `.eslintrc.js`, `.gitignore`.
  - `src/index.ts` is an empty re-export stub.
  - `npm install` ran clean (703 packages). `npm run build` (`tsc`) succeeds.
- Root Firebase config:
  - `firebase.json` — wires Firestore, Storage, Functions, and the emulator suite (auth 9099, functions 5001, firestore 8080, storage 9199, UI on).
  - `.firebaserc` — three project aliases: `dev → dutch-lanka-dev`, `staging → dutch-lanka-staging`, `prod → dutch-lanka-prod`. `default` points at dev.
  - `firestore.rules` — `allow read, write: if false;` for everything. Stub.
  - `firestore.indexes.json` — empty arrays.
  - `storage.rules` — deny-all stub.
- Root `README.md` — overview paragraph + the common commands from `CLAUDE.md`.
- Root `.gitignore` — already existed in the repo from the initial commit; left untouched. Verified it covers Flutter (`build/`, `.dart_tool/`, generated `*.g.dart`/`*.freezed.dart`), Node (`functions/node_modules/`, `functions/lib/`), Firebase (`.firebase/`, debug logs), env/secrets (`.env*`, `*.key`, `service-account*.json`, `firebase_options_prod.dart`, prod `google-services.json` / `GoogleService-Info.plist`), and IDE files.

**Deviations from the prompt:**

1. **Did not run `firebase init functions`.** That command is interactive and requires an authenticated `firebase login` plus an existing Firebase project to associate with. I scaffolded `functions/` manually to match the same output (TypeScript, ESLint, deps installed). When the three Firebase projects (`dutch-lanka-dev/staging/prod`) are created, we can run `firebase use --add` to associate them and `firebase init functions` again if anything looks off — but the directory structure is already correct. Flagged in "Decisions" below.

2. **The pre-existing `.gitignore` was reused, not rewritten.** The previous commit `c54f55d` already added a comprehensive `.gitignore`. I verified it covers everything `CLAUDE.md` requires (including `firebase_options_prod.dart`, prod platform configs, PayHere live secrets, service account keys) and left it as-is rather than overwriting.

**Decisions made:**

- Firebase region was not pinned in `firebase.json` (Cloud Functions catalog in `architecture.md` §6 specifies `asia-south1`). That's a per-function decision in TS code, not a project-level config — will set when functions are added.
- Used the Firebase emulator UI port defaults plus `singleProjectMode: true` so emulator runs cleanly with whichever project is active.
- ESLint config uses `eslint-config-google` + `@typescript-eslint/recommended` (the `firebase init functions` default), not Airbnb or stricter — matches what new contributors will expect from a Firebase project.

**TODOs / not done in this step:**

- Flutter flavors (`main_dev.dart` / `main_staging.dart` / `main_prod.dart`) and per-flavor build configs.
- `flutterfire configure` to generate `firebase_options_*.dart` (requires the three Firebase projects to exist).
- `pubspec.yaml` deps for Riverpod, GoRouter, Freezed, lucide_icons, etc. — not added yet, deliberately out of scope for "scaffold only".
- `packages/shared` library exports (`theme/`, `widgets/`) — empty package for now.
- Real Firestore/Storage rules. The deny-all stubs are placeholders — they need to be replaced before the apps can read anything in dev.

---

## Known issues

- **`functions/` `npm install` reported 11 vulnerabilities (2 low, 9 moderate)** in transitive deps inside `firebase-tools`/`firebase-admin`. Standard for a fresh Firebase Functions install. Not addressing now; will revisit if any are flagged as high/critical or affect runtime code.
- **No Firebase projects exist yet.** `.firebaserc` references `dutch-lanka-dev/staging/prod` but they have not been created in the Firebase console. `firebase deploy` and `firebase emulators:start` against real auth flows will fail until they are. Emulators-only workflows still work.
- **`.env.example` was deleted in the working tree** (visible in `git status` since session start). Unrelated to this step; left for the user to handle.

---

## Decisions

- **Manual `functions/` scaffold instead of `firebase init functions`.** Reason: the CLI is interactive and needs `firebase login` + a real project. Scaffolding manually produces the same on-disk result and unblocks the next step. If `firebase init functions` is run later against a real project, it will detect the existing `package.json` and prompt before overwriting.
- **`.firebaserc` uses the `dutch-lanka-*` project IDs from `architecture.md` §9, not the `sugar-studio-*` IDs mentioned in `CLAUDE.md` §"Firebase environments".** The two docs disagree. `architecture.md` is the more recent and project-named "Dutch Lanka"; `CLAUDE.md` mentions `sugar-studio-*` likely as a holdover. Picked `dutch-lanka-*` because it matches the repo name and the project name in `pubspec.yaml`. **Worth confirming with the user before creating the actual Firebase projects.**
- **Default-deny rules everywhere.** Per architecture rule "Firestore Rules enforce [the no-direct-writes invariant]" and the playbook "default deny, then add the minimum read/write the client needs". Easier to open up per-collection later than to lock down a permissive baseline.
