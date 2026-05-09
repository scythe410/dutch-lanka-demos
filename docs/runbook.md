# Dutch Lanka — operations runbook

Day-2 operations for the Firebase backend and the two Flutter apps. Pair this with `architecture.md` (system map) and `progress.md` (current state). When in doubt, prefer the safer path: running an extra emulator check is cheap, a bad prod deploy is not.

---

## 0. Prerequisites

- Firebase CLI logged in: `firebase login` (account with **Owner** on both `dutch-lanka-dev` and `dutch-lanka-prod`).
- Local `.env` files present at `apps/customer/.env` and `apps/manager/.env` with the dev-only Maps key.
- Node 20, Flutter 3.x, Java 17 on PATH.
- Authorised aliases configured: `firebase use --add` once per machine for both projects (`dev`, `prod`).

Project switching is explicit on every deploy command — never rely on the active alias to be correct. Use `--project dutch-lanka-prod` (or `dev`) on every Firebase CLI invocation that mutates state.

---

## 1. Deploying to production (with manual approval gate)

The deploy is a two-stage flow: dry-run against dev, then a checklist-gated promote to prod. There is **no auto-deploy from `main`**. CI builds, you approve, you push.

### 1.1 Pre-flight (5 min)

From a clean working tree on `main`:

```
git pull --ff-only
flutter analyze              # in apps/customer, apps/manager, packages/shared
flutter test                 # in apps/customer, apps/manager, packages/shared
( cd functions && npm run lint && npm run build && npm run test:functions )
```

All four must be green. If any flake, **stop and fix** — don't redeploy a flake into prod.

### 1.2 Stage to dev (verifies the deploy itself works)

```
firebase use dev
firebase deploy --only firestore:rules,firestore:indexes --project dutch-lanka-dev
firebase deploy --only storage --project dutch-lanka-dev
firebase deploy --only functions --project dutch-lanka-dev
```

**First-time-on-a-new-project gotchas** (only matter the first time):

- `firebase deploy --only storage:rules` (with the `:rules` suffix) errors with "Could not find rules for the following storage targets: rules" on projects that have the new `firebasestorage.app` bucket format. Use `--only storage` instead — the CLI then resolves the default bucket itself.
- The first Functions deploy will demand a sequence of one-click API enables (Cloud Functions, Cloud Build, Artifact Registry, Eventarc, Pub/Sub, Run, Secret Manager). Just keep retrying — each error message links to the enable page.
- `defineSecret` parameters (e.g. `PAYHERE_MERCHANT_SECRET`) need the value set in Secret Manager before deploy: `firebase functions:secrets:set PAYHERE_MERCHANT_SECRET --project dutch-lanka-dev`.
- The deploy may print three `gcloud projects add-iam-policy-binding ...` commands ("We failed to modify the IAM policy for the project"). Run them as project Owner; they grant `roles/iam.serviceAccountTokenCreator` to the Pub/Sub agent and `roles/run.invoker` + `roles/eventarc.eventReceiver` to the compute service account. Then retry.
- 2nd-gen Firestore-trigger functions (`onOrderCreate`, `onOrderStatusChange`) frequently fail on the **first** deploy with "Permission denied while using the Eventarc Service Agent" while the agent's permissions propagate. The CLI suggests "Retry the deployment in a few minutes" — wait ~3 min and re-deploy just those two: `firebase deploy --only functions:onOrderCreate,functions:onOrderStatusChange --project dutch-lanka-dev`.

Smoke against dev:

- Sign in as a customer; place a sandbox PayHere order (test card `4916217501611292`).
- Confirm `payhereNotify` flips `paymentStatus → paid` (Firestore listener in the app updates from "processing" within ~5s).
- Sign in as a manager; advance the order through `paid → preparing → dispatched → delivered`.
- Trigger a low-stock alert (drop a product's `stock` below threshold via the manager UI) and confirm an FCM push lands on the manager device.

If any of those fail, fix on dev first. **Never deploy to prod with broken dev.**

### 1.3 Manual approval gate

Before `firebase use prod`, you must:

1. **Tag the commit** — `git tag -a v$(date +%Y.%m.%d) -m "prod release"`.
2. **Post in #ops** — link to the tag + 1-line summary of what's changing. Wait for ack from a second engineer.
3. **Confirm freeze window** — no in-flight orders. The customer app has no maintenance banner yet, so coordinate around quiet hours (Sri Lanka time, after 11pm or before 6am).
4. **Snapshot Firestore** — `gcloud firestore export gs://dutch-lanka-prod-backups/$(date +%Y%m%d-%H%M)` so a rollback has somewhere to restore from.

Only after all four boxes are ticked do you proceed.

### 1.4 Deploy to prod

```
firebase use prod
firebase deploy --only firestore:rules,storage:rules,firestore:indexes \
                --project dutch-lanka-prod
firebase deploy --only functions --project dutch-lanka-prod
```

The CLI prints each function it's deploying. Watch it — if a function build fails, the CLI keeps going on the others. **Always read the summary**.

### 1.5 Post-deploy verification (mandatory, 10 min)

Run the same smoke as 1.2 against prod with a real-money small-amount sandbox card before any customer traffic hits the new build. If anything looks off, **roll back immediately** (§4).

App store builds (Play / App Store Connect) are uploaded separately — they sign and go through their own staged rollout. Don't let app-build issues block a backend rollback; they're orthogonal.

### 1.6 Push the tag

After verification clears:

```
git push origin v2026.05.08          # the tag from §1.3
```

The tag in remote is the audit trail for what's running.

---

## 2. Provisioning a new manager / staff account

Managers cannot self-sign-up — the manager app has no signup screen on purpose. Roles are stored as Auth custom claims (`role: "manager" | "staff"`). Only an existing manager can promote.

### 2.1 First-ever manager (bootstrap)

The first manager has to be promoted out-of-band, since the in-app Staff page is unreachable until at least one manager exists. Detailed steps live in `progress.md` → "Bootstrap a manager". Summary:

1. Create the user in Firebase Auth (Console → Users → Add).
2. From `functions/`, run `npm run shell` and call:
   ```
   setManagerRole(
     {targetUid: '<uid>', role: 'manager'},
     {auth: {uid: 'bootstrap', token: {role: 'manager'}}}
   )
   ```
3. The user signs in to the manager app and lands on `/dashboard`.

For prod, the second argument must be a real authenticated manager — there is no "bootstrap" hatch on prod. Promote the first prod manager from a dev session if you have to: deploy `setManagerRole` to dev, promote there, then deploy to prod (the function reads the caller's claim from the token, so the dev-issued claim doesn't carry over — you'll need an admin script with a service-account-issued ID token instead).

### 2.2 Routine promotion

From the manager app:

1. Sign in as an existing manager.
2. **More → Staff**.
3. The user must already exist in Firebase Auth. If they signed up via the customer app, they'll appear in the customer list at More → Customers — note their UID.
4. On the Staff screen, either pick the user from the list and change their role via the dropdown, **or** use the "Promote a customer" card and paste the UID.
5. The change is server-side — the target user must sign out and back in for the new claim to take effect (Firebase Auth caches the ID token for ~1 hour by default).

Demotion follows the same flow. The Function refuses self-demotion to prevent locking the org out of role admin.

---

## 3. Running the seeder against dev

The seeder lives at `tools/seed.ts`. It refuses to run unless the emulator environment variables are set, so it cannot accidentally write to prod.

### 3.1 Local emulator

```
# Terminal A — emulator suite
firebase emulators:start --project dutch-lanka-dev

# Terminal B — seed
cd functions
npm run seed
```

`npm run seed` sets the required env vars (`FIRESTORE_EMULATOR_HOST=localhost:8080` and `FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`) and points `GCLOUD_PROJECT` at `dutch-lanka-dev` by default.

Output: a deterministic set of products, ingredients, low-stock alerts, and at least one demo customer. Re-running is idempotent — it `set`s by deterministic IDs.

### 3.2 Against the deployed dev project (rare)

Don't. The seeder is for local emulators. To populate the deployed dev project, write a one-shot script that uses a service-account key — never re-purpose the emulator seeder.

If you absolutely must, the gate is: **Firebase project = `dutch-lanka-dev`** (never prod), and the operator confirms in #ops first.

---

## 4. Rolling back Cloud Functions

Cloud Functions deploys are versioned but the CLI doesn't expose a one-liner rollback. The safe path is to redeploy the prior commit.

### 4.1 Fast rollback (minutes)

```
git fetch --tags
git checkout <previous-tag>          # e.g. v2026.05.07
( cd functions && npm install && npm run build )
firebase use prod
firebase deploy --only functions --project dutch-lanka-prod
git checkout main                    # don't leave the working tree detached
```

Rules and indexes follow the same pattern (`--only firestore:rules` etc.) but rules rollbacks are rarer — most rule incidents need a forward-fix, not a revert.

### 4.2 Targeted rollback (one bad function)

If only one Function is broken, redeploy just that one from the prior tag:

```
git checkout <previous-tag> -- functions/src/functions/<name>.ts
( cd functions && npm run build )
firebase deploy --only functions:<name> --project dutch-lanka-prod
```

This is faster than a full functions deploy and avoids re-uploading good code. Confirm the deploy log shows only the one function changing.

### 4.3 Aborting in-flight requests

There is no per-deployment kill switch. If a Function is actively breaking, the rollback above is the fix. Setting `firebase functions:config:set kill.<name>=true` and reading it in the function as a feature flag is a TODO — don't try to bolt it on during an incident.

### 4.4 Firestore data rollback

Use the export taken in §1.3. Restore via `gcloud firestore import gs://dutch-lanka-prod-backups/<timestamp>`. **This overwrites the entire database** — only run during a confirmed maintenance window with all writes paused.

---

## 5. Where logs live

| Source | Location | Retention | Notes |
|---|---|---|---|
| Cloud Functions stdout/err | Firebase Console → Functions → Logs (or `firebase functions:log`) | 30 days default | PII redaction is enforced in code per CLAUDE.md rule 6 |
| Cloud Functions (queryable) | GCP Console → Logs Explorer, project `dutch-lanka-prod` | 30 days | Filter by `resource.type="cloud_function"` |
| Firestore Rules denials | GCP Console → Logs Explorer → `resource.type="datastore_database"` + severity `WARNING` | 30 days | Surface unexpected client behaviour |
| Auth events (sign-in / signup) | Firebase Console → Authentication → Users (last sign-in column) | indefinite | Full audit log via GCP Audit Logs |
| Crashlytics (Flutter crashes) | Firebase Console → Crashlytics | 90 days | Wired in `apps/*/lib/firebase/bootstrap.dart`. `kDebugMode` builds skip reporting |
| Performance Monitoring | Firebase Console → Performance | 90 days | Auto-traces network + screen render — no manual instrumentation yet |
| App Check denials | Firebase Console → App Check → metrics tab | 30 days | Watch for unexpected enforcement failures after a release |
| PayHere webhook traffic | Cloud Functions logs for `payhereNotify` | 30 days | MD5 verification failures show as `WARNING` — investigate every spike |
| Android device logs (debug) | `flutter logs` while connected via USB | session only | App Check debug tokens print here on first run |

For an incident, start with Crashlytics (fatal) → Cloud Functions logs (server-side) → Logs Explorer (cross-cutting). The Logs Explorer query language is the most powerful — keep `resource.type` and `severity` filters handy.

---

## 6. Triggering a Crashlytics test crash

Validate the pipeline once per release on a real device:

1. Build prod for the app under test:
   ```
   flutter run --flavor prod -t lib/main_prod.dart --release
   ```
2. From the running app, navigate to a screen and trigger a deliberate crash. The codebase doesn't ship a "test crash" button on purpose — invoke from the Dart DevTools console or temporarily add a crash button behind a debug menu and remove before the next build:
   ```dart
   FirebaseCrashlytics.instance.crash();
   ```
3. Wait for the next launch (Crashlytics flushes on the *next* run). Re-open the app.
4. Within ~5 minutes, the event appears in Firebase Console → Crashlytics → Issues for the matching app.

Run this on both Android and iOS — symbol upload differs per platform and silent breakage is the failure mode you're guarding against.

---

## 7. App Check debug tokens

Dev builds run App Check in **debug provider** mode (`AndroidProvider.debug` / `AppleProvider.debug`). On first launch, the SDK prints:

```
Enter this debug secret into the Firebase console... <UUID>
```

to logcat (Android) or the Xcode console (iOS). To allow that device through enforcement during dev:

1. Firebase Console → App Check → **Apps** tab → pick the app → **Manage debug tokens**.
2. Paste the UUID, give it a memorable name (`alice-pixel-7`), save.

Tokens never expire; revoke when a device is decommissioned. Production builds use Play Integrity / DeviceCheck and have no debug-token equivalent.
