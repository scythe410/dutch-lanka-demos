# Dutch Lanka

Dutch Lanka is a mobile-first bakery ordering and management system for a single bakery in Sri Lanka. Two Flutter apps — a customer app (`apps/customer`) and a manager app (`apps/manager`) — talk to a Firebase backend (Auth, Firestore, Storage, FCM, Cloud Functions) with PayHere for payments. Both apps share models, theme, and widgets via `packages/shared`. The full architecture is in `docs/architecture.md` and the visual design system in `docs/design.md`.

## Repository layout

```
apps/customer/   Customer-facing Flutter app
apps/manager/    Manager Flutter app
packages/shared/ Shared Dart package: models, theme, widgets, utils
functions/       Firebase Cloud Functions (Node.js + TypeScript)
docs/            Architecture and design docs
```

## Common commands

### Flutter (run inside `apps/customer/` or `apps/manager/`)

```
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
flutter analyze
flutter test
flutter build apk  --flavor prod -t lib/main_prod.dart --release
flutter build ipa  --flavor prod -t lib/main_prod.dart --release
```

### Cloud Functions (run inside `functions/`)

```
npm install
npm run build
npm run lint
npm run test
npm run serve
firebase deploy --only functions
```

### Firebase

```
firebase emulators:start
firebase use dev | staging | prod
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

See `CLAUDE.md` for the full set of architectural rules and coding conventions.
