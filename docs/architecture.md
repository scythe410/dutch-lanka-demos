# Dutch Lanka — System Architecture

A serverless, mobile-first architecture for the Dutch Lanka bakery — a single-location ordering and management system in Sri Lanka. Built to run on Firebase's free tier for the demo phase, with a clean migration path to a paid tier once orders start flowing.

---

## 1. Executive summary

| Aspect | Decision |
|---|---|
| Scope | Single bakery, one location |
| Region | Sri Lanka (LKR currency, local payment methods) |
| Mobile framework | Flutter (single codebase → Android + iOS) |
| Backend | Firebase BaaS + Cloud Functions (serverless) |
| Database | Cloud Firestore (real-time NoSQL) |
| Payments | PayHere (Sri Lanka — cards, eZ Cash, mCash, Genie, FriMi, Vishwa) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Maps | Google Maps Platform (free $200/mo credit) |
| Hosting cost | LKR 0 for demo (Spark plan covers everything; email auth has no SMS cost) |

The architecture has three tiers: two Flutter mobile clients on top, Firebase services in the middle (with Cloud Functions as the only place we run custom backend code), and three external integrations at the bottom.

---

## 2. Stack decisions

### Why Flutter (not native, not React Native)
With Android + iOS required from day one, native development means writing every screen twice in two different languages. Flutter compiles to native code on both platforms from a single Dart codebase, has first-party Firebase support via `flutterfire`, and ships an official PayHere SDK. React Native is the close runner-up; the choice between them is largely a team-skill question. Flutter has the edge for graphics-heavy UIs (which a bakery menu benefits from) and a more mature dev experience for pure-mobile apps.

### Why Firebase (not AWS, not self-hosted)
Three reasons matter for a demo:

1. **Permanent free tier.** The Spark plan isn't a 12-month trial — it stays free as long as usage stays under the limits. For one bakery, that ceiling is generously above the demo's needs.
2. **Mobile-native.** Auth, real-time DB, push notifications, image storage, and serverless functions are all in one console with one SDK. No glue code for "send a notification when an order is created" — it's a Firestore trigger.
3. **Real-time tracking comes for free.** Firestore listeners push status changes to the customer's app instantly. Implementing the same pattern on a traditional backend would require WebSockets or polling.

### Why serverless (not monolith, not microservices)
A monolith needs an always-on server, which costs money even when idle — defeating the "free demo" goal. Microservices are massive overkill for a single-bakery workload. Serverless via Cloud Functions means code only runs when triggered (new order, payment webhook, etc.), and the free tier covers 2 million invocations per month.

### Why PayHere (not Stripe, not bank IPGs)
Stripe doesn't onboard Sri Lankan businesses to receive payments. Among local options, PayHere is the most widely adopted, Central Bank of Sri Lanka approved, and supports the full spread of local payment methods customers actually use — Visa/Mastercard, plus eZ Cash, mCash, Genie, FriMi, and bank gateways like Vishwa. It also ships official Flutter and React Native SDKs with sandbox mode (free for demo).

---

## 3. Component specifications

### 3.1 Customer mobile app (Flutter)

Built as a single Flutter app published to both Google Play and the App Store from one codebase. Uses the BLoC or Riverpod pattern for state management (recommend Riverpod for simplicity).

Key SDKs:
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- `payhere_mobilesdk_flutter` — in-app payment without redirecting to a browser
- `google_maps_flutter` — embedded map for delivery tracking
- `geolocator` — request and read GPS location
- `flutter_local_notifications` — display FCM messages while app is foregrounded
- `image_picker` — for profile photos (optional)

Screens map directly to SRS sections 1.5.1–1.5.8: onboarding/email signup + verification, home (browse), product detail, cart, checkout, order tracking, order history, profile, addresses, ratings.

### 3.2 Manager mobile app (Flutter)

Separate Flutter app — same framework, same Firebase project, different package ID and entitlements. Only users with the `manager` or `staff` custom claim can sign in.

Adds these SDKs on top of the customer app's stack:
- `fl_chart` or `syncfusion_flutter_charts` — for the analytics dashboard (SRS 2.5.7)
- `image_picker` + `firebase_storage` — for uploading product photos directly from the manager's phone

Screens map to SRS sections 2.5.1–2.5.9: login, dashboard (sales/orders/stock at a glance), order list with filters, order detail with status controls, product CRUD, inventory list, reports/charts, customer list, complaints inbox.

### 3.3 Firebase Authentication

Two separate sign-in methods, used by the two apps:

- **Customer app:** Email + password, with email verification at signup. Firebase sends a verification email containing either a 4-digit code (per the design screenshots' "Verify Code" screen) or a verification link — implementation choice. Free, no SMS cost.
- **Manager app:** Email + password. Manager accounts are created manually in the Firebase console (or via a one-time Cloud Function script) — there is no public manager signup.

Role-based access is enforced through **custom claims** set on the user record: `role: "customer"`, `role: "manager"`, or `role: "staff"`. Claims are read inside Firestore Security Rules and inside the apps to gate screens.

### 3.4 Cloud Firestore

The single source of truth. Every read and write from the mobile apps goes through Firestore directly (subject to Security Rules) — there is no custom REST API layer. This is the pattern Firestore is designed for.

Real-time listeners (`onSnapshot` in the SDK) are used wherever the UI must reflect changes from the server: order status on the customer side, incoming-order list and stock levels on the manager side. The full data model is in Section 6.

### 3.5 Firebase Storage

Stores product images uploaded by the manager. Each product document in Firestore holds a Storage path (e.g. `products/{productId}/main.jpg`); the app downloads the image via the Firebase Storage SDK with a signed URL. Storage rules mirror Firestore rules — only managers can write, anyone authenticated can read.

### 3.6 Firebase Cloud Messaging (FCM)

Handles all push notifications, free and unlimited. Token registration: each app stores its FCM token in the user's Firestore document on login. Cloud Functions look up the token when sending.

Notification triggers (from SRS 1.5.7 and 2.5.6):

| Event | Recipient | Payload |
|---|---|---|
| Order placed | Customer + all managers | Order ID, total |
| Order status change | Customer | New status |
| Low stock | Managers | Item name, current qty |
| Promotion | Selected customers | Marketing message |
| New complaint | Managers | Complaint summary |

### 3.7 Cloud Functions for Firebase

The only place custom backend code runs. Written in Node.js (TypeScript recommended for type safety with Firestore documents). Full function catalog in Section 7.

Three trigger types are used:
- **Auth triggers** — fire on user creation/deletion (e.g. set up a Firestore profile doc).
- **Firestore triggers** — fire on document writes (e.g. when an order doc is created, decrement stock and notify managers).
- **HTTP triggers** — webhooks. Specifically, the PayHere `notify_url` posts here.

### 3.8 PayHere (external)

Integrated via `payhere_mobilesdk_flutter`. The flow:

1. Mobile app calls a Cloud Function (`createOrder`) which writes a pending order to Firestore and returns the order ID + computed total + a server-generated MD5 hash for PayHere.
2. App opens the PayHere SDK with the order details. PayHere shows its in-app payment UI; the user pays with cards or any local method.
3. PayHere posts a server-to-server notification to a Cloud Function (`payhereNotify`) — this is the trusted source of payment status. The app's own success callback is *not* trusted for state changes (it can be spoofed).
4. The Cloud Function verifies the MD5 signature, updates the order doc to `paid`, and triggers downstream functions.

Sandbox merchant credentials are free and behave identically to live for end-to-end testing.

### 3.9 Google Maps Platform

Used in two places:
- **Delivery tracking map** in the customer app — displays the bakery location, the customer's address, and (when active) the delivery person's live location.
- **Geocoding** — converts saved customer addresses to lat/lng so the bakery can see them on a map.

Free tier: Google gives every project a US$200/month credit, which covers ~28,000 dynamic map loads. A demo will not get close.

### 3.10 Email verification (no SMS gateway)

Per the design, customer authentication is email-based, so no SMS gateway is required. Firebase Auth sends verification emails through Google's own infrastructure at no cost. The design's "Verify Code" screen (a 4-digit code entry rather than a link click) can be implemented one of two ways:

- **Custom email verification.** A Cloud Function generates a 6-digit code, stores its hash in Firestore with a TTL, and sends a templated email via SendGrid/Mailgun (both have free tiers). The app submits the code to a `verifyEmailCode` callable Function. More work, fully matches the design.
- **Firebase email link.** Use Firebase's built-in email-link sign-in. The user taps a link in the email and the app handles the deep link. Less work, but the UX diverges from the "enter 4 digits" screen in the design.

For the demo, the email-link approach is faster to ship; if the 4-digit UX is important, build it the custom way. Either way: zero SMS cost.

---

## 4. Data flow scenarios

### 4.1 Customer registration & first login

```
App                    Firebase Auth         Firestore        Cloud Function
 │                          │                   │                   │
 ├─ enter email + password ▶│                   │                   │
 │                          ├─ create user ─────▶│                  │
 │                          │                   ├─ onUserCreate ───▶│
 │                          │                   │◀─ create profile ─┤
 │                          ├─ send verify email┤                   │
 │◀─ email arrives ─────────┤                   │                   │
 ├─ enter 4-digit code ────▶│                   │                   │
 │◀─ verified, logged in ───┤                   │                   │
```

The `onUserCreate` Auth trigger writes a default Firestore document at `users/{uid}` with `role: "customer"` and empty profile fields. The app then reads that doc and routes to the profile-completion screen.

### 4.2 Browse and order placement

The product catalog lives in Firestore at `/products/{productId}`. The customer app subscribes with a real-time listener — if the manager edits a price or marks something out of stock, the customer's screen updates within a second.

The cart is held in app state (not Firestore — no need to sync across devices for this demo). On checkout, the app calls the `createOrder` Cloud Function with cart contents, delivery address, and payment method. The function:

1. Validates each item is still in stock and the prices match the current Firestore values (server-side anti-tampering).
2. Calculates the total.
3. Writes a new doc to `/orders/{orderId}` with `status: "pending_payment"`.
4. Returns the order ID and a PayHere payment payload (with MD5 hash).

### 4.3 Payment

The app receives the payment payload and invokes the PayHere SDK. PayHere handles the entire payment UI in-app and returns one of three callbacks (success / dismissed / error). Critically, the app **does not** trust the success callback for committing the order — it just shows a "processing payment" screen.

The truth comes from PayHere's server-to-server `notify_url`, which hits the `payhereNotify` HTTP Cloud Function. That function:

1. Verifies the MD5 signature using the merchant secret (proves the request actually came from PayHere).
2. Looks up the order by `order_id`.
3. If `status_code == 2` (success), updates the order to `status: "paid"`. Other status codes map to `failed`, `cancelled`, etc.

Once the order doc updates to `paid`, the `onOrderStatusChange` Firestore trigger fires and notifies the customer + managers via FCM. The app's success screen is driven by its own real-time listener on the order doc — no polling needed.

### 4.4 Real-time order tracking

After payment, the customer opens the order detail screen. The screen subscribes to `/orders/{orderId}` via `snapshots()`. Every status change pushed by the manager (or by Cloud Functions) updates the UI immediately.

For GPS tracking once the order is dispatched: the assigned delivery person's app (the manager app, with a "delivery mode" toggle, or eventually a separate driver app) writes location updates to `/orders/{orderId}/tracking` every 10–30 seconds. The customer app subscribes to that subcollection and updates the map marker.

### 4.5 Manager: receive new order

When `createOrder` writes a new order doc, the `onOrderCreate` Firestore trigger fires:

1. Decrements stock counts in `/products/{productId}` (atomic transaction).
2. If any item drops below its `lowStockThreshold`, writes to `/lowStockAlerts/`.
3. Sends an FCM push to all users with `role: "manager"`.

The manager app's home screen has a real-time listener on `orders` filtered to today + `status in [paid, preparing]`. New orders appear at the top instantly.

### 4.6 Low-stock alert

Same `onOrderCreate` trigger above writes a `/lowStockAlerts/{alertId}` document. A separate trigger on that collection sends FCM notifications. The two-step approach keeps the order-creation transaction fast and lets us add deduplication ("don't alert again for 1 hour for the same item") without complicating the order logic.

---

## 5. Firestore data model

```
/users/{uid}
  ├─ email: string
  ├─ emailVerified: bool
  ├─ phone: string?
  ├─ name: string
  ├─ photoUrl: string?
  ├─ role: "customer" | "manager" | "staff"   (mirror of custom claim)
  ├─ fcmTokens: string[]
  ├─ createdAt: timestamp
  └─ /addresses/{addressId}
       ├─ label: "Home" | "Work" | string
       ├─ line1, line2, city, postalCode
       ├─ lat, lng
       └─ isDefault: bool

/products/{productId}
  ├─ name: string
  ├─ description: string
  ├─ category: "cake" | "bread" | "pastry" | ...
  ├─ price: number       (LKR)
  ├─ imagePath: string   (Firebase Storage path)
  ├─ stock: number
  ├─ lowStockThreshold: number
  ├─ available: bool
  ├─ customizable: bool  (e.g. cake text)
  ├─ createdAt, updatedAt
  └─ /reviews/{reviewId}
       ├─ userId, userName
       ├─ rating: 1..5
       ├─ comment: string
       └─ createdAt

/orders/{orderId}
  ├─ customerId: string (uid)
  ├─ items: [{ productId, name, qty, unitPrice, customizations? }]
  ├─ subtotal, deliveryFee, total: number
  ├─ deliveryAddress: { line1, line2, city, lat, lng }
  ├─ paymentMethod: "card" | "ezcash" | "mcash" | ... | "cod"
  ├─ paymentStatus: "pending" | "paid" | "failed" | "refunded"
  ├─ payherePaymentId: string?
  ├─ status: "pending_payment" | "paid" | "preparing" | "dispatched" | "delivered" | "cancelled"
  ├─ assignedDeliveryUid: string?
  ├─ createdAt, paidAt, dispatchedAt, deliveredAt
  ├─ /statusHistory/{eventId}
  │    ├─ status, changedBy, timestamp, note
  └─ /tracking/{pingId}
       ├─ lat, lng, timestamp, deliveryUid

/lowStockAlerts/{alertId}
  ├─ productId, productName, currentStock, threshold
  ├─ createdAt
  └─ acknowledged: bool

/complaints/{complaintId}
  ├─ customerId, orderId?
  ├─ subject, body
  ├─ status: "open" | "resolved"
  ├─ createdAt, resolvedAt
  └─ /messages/{msgId}     (back-and-forth)

/promotions/{promoId}
  ├─ title, body, imagePath
  ├─ targetSegment: "all" | "new_customers" | ...
  ├─ active: bool, expiresAt
```

A few design notes:

- **Cart is not in Firestore.** It lives in app state only. Adding it to Firestore would mean writing on every "+1 item" tap, which is wasteful. It's only persisted at checkout via `createOrder`.
- **`statusHistory` as a subcollection** rather than an embedded array keeps the parent order document small and lets us paginate the history if it grows.
- **`fcmTokens` is an array** because the same user might be logged in on phone + tablet. We append on login and remove on logout.

---

## 6. Cloud Functions catalog

| Function | Trigger | Purpose |
|---|---|---|
| `onUserCreate` | Auth `onCreate` | Initialize `/users/{uid}` profile doc with default role |
| `onUserDelete` | Auth `onDelete` | Soft-delete user data; keep orders for accounting |
| `setManagerRole` | HTTPS callable (admin-only) | Set `role: "manager"` custom claim on a user |
| `createOrder` | HTTPS callable | Validate cart, create order doc, return PayHere payload |
| `payhereNotify` | HTTPS | PayHere webhook; verify MD5, update order paymentStatus |
| `onOrderCreate` | Firestore `onCreate` `/orders/{orderId}` | Decrement stock atomically, notify managers, check low-stock |
| `onOrderStatusChange` | Firestore `onUpdate` `/orders/{orderId}` | Notify customer of new status, write `statusHistory` event |
| `onLowStockAlert` | Firestore `onCreate` `/lowStockAlerts/{id}` | Send FCM to all managers (with hourly dedupe per product) |
| `onComplaintCreate` | Firestore `onCreate` `/complaints/{id}` | Notify managers |
| `dailySalesReport` | Scheduler (cron, daily 11pm) | Aggregate today's orders, write `/reports/daily/{date}` |
| `assignDelivery` | HTTPS callable (manager-only) | Set `assignedDeliveryUid` on order, notify the assignee |

Functions are deployed to a single Sri Lanka–closest region (`asia-south1` in Mumbai) for lowest latency to end users.

---

## 7. Security architecture

### 7.1 Firebase Authentication + custom claims

Every authenticated user has a `role` custom claim set from a privileged Cloud Function (`setManagerRole` / `onUserCreate`). The claim is signed by Firebase and present in every request — Firestore Rules and Cloud Functions read it without an extra DB round-trip.

### 7.2 Firestore Security Rules

The rules file is the system's primary access-control surface. A simplified excerpt:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function isAuthed()      { return request.auth != null; }
    function role()          { return request.auth.token.role; }
    function isCustomer()    { return role() == 'customer'; }
    function isManager()     { return role() == 'manager'; }
    function isStaff()       { return role() in ['manager', 'staff']; }
    function isOwner(uid)    { return request.auth.uid == uid; }

    // Users: read own doc; managers read any
    match /users/{uid} {
      allow read: if isOwner(uid) || isManager();
      allow create: if false;            // Cloud Function only
      allow update: if isOwner(uid)
                    && !('role' in request.resource.data.diff(resource.data).affectedKeys());
      match /addresses/{addressId} {
        allow read, write: if isOwner(uid);
      }
    }

    // Products: anyone authed reads; only managers write
    match /products/{productId} {
      allow read: if isAuthed();
      allow write: if isManager();
      match /reviews/{reviewId} {
        allow read: if isAuthed();
        allow create: if isCustomer()
                      && request.resource.data.userId == request.auth.uid;
      }
    }

    // Orders: customer reads own; staff reads all; nobody writes from client
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.customerId) || isStaff();
      allow create, update, delete: if false;   // Cloud Functions only
      match /tracking/{pingId} {
        allow read: if isOwner(get(/databases/$(db)/documents/orders/$(orderId)).data.customerId)
                    || isStaff();
        allow create: if isStaff();
      }
    }

    // Low-stock alerts: managers only
    match /lowStockAlerts/{id} {
      allow read, write: if isManager();
    }
  }
}
```

The pattern: clients can read what they own and a few public collections, but **all writes that mutate business state go through Cloud Functions** (orders, payments, role changes, stock decrements). This keeps the client untrusted.

### 7.3 PayHere webhook verification

Every `payhereNotify` request is verified by reconstructing the MD5 hash from `merchant_id + order_id + payhere_amount + payhere_currency + status_code + uppercase(md5(merchant_secret))` and comparing against the `md5sig` parameter PayHere sends. Mismatched signatures are rejected with HTTP 401. The merchant secret never leaves Cloud Functions environment config.

### 7.4 Firebase App Check

Enabled on Firestore, Storage, and HTTPS Cloud Functions. App Check ensures requests come from genuine instances of your app (using Play Integrity API on Android and DeviceCheck/App Attest on iOS), blocking traffic from emulators, repackaged APKs, and direct API hits with stolen credentials.

### 7.5 Sensitive data handling

- **Payment card details never touch our infrastructure.** PayHere collects them in its own SDK UI; we only ever see a payment ID.
- **Email addresses and phone numbers** are stored only in the user's own document (read-protected by rules).
- **Firebase API keys are not secrets** — they identify the project, not authorize access. The rules and App Check do the actual gating. This is a common confusion worth documenting.

---

## 8. Cost analysis

### Demo phase (Spark plan, free)

| Service | Free quota | Demo usage | Cost |
|---|---|---|---|
| Firebase Auth | Unlimited (email/password + verification emails) | Low | $0 |
| Firestore | 1 GB stored, 50k reads/20k writes/20k deletes per day | Small fraction | $0 |
| Firebase Storage | 5 GB stored, 1 GB/day download | Small | $0 |
| FCM | Unlimited | Any | $0 |
| Cloud Functions | 125k invocations/month, 40k GB-seconds | Small | $0 |
| Google Maps | $200/month credit | <$10 likely | $0 |
| PayHere | No setup fee, free sandbox | Sandbox only | $0 |
| **Total demo cost** | | | **$0/month** |

### Production phase (after launch)

Once the demo becomes a real bakery, the main cost driver is PayHere transaction fees (~2.5–3.9% per transaction, paid by the bakery). A bakery doing 100 orders/day would run roughly:

- PayHere: 2.5% of revenue (paid by the bakery, not Firebase)
- Email verification: free at any reasonable volume (Firebase email-link) or ~$0 with SendGrid's free tier (100 emails/day for custom code emails)
- Firestore: still likely free; would only need the Blaze plan to *enable* paid features
- Cloud Functions: still likely free

The Spark plan can hard-limit usage; the Blaze (pay-as-you-go) plan is needed only when you want to send notify-url webhooks to non-Google domains, which we do for PayHere. **You'll need Blaze on day one** for the PayHere webhook to work — but with Firestore/Functions usage well below the free thresholds, the bill stays at $0 until traffic genuinely scales.

---

## 9. Deployment & DevOps

### Environments
Three Firebase projects: `dutch-lanka-dev`, `dutch-lanka-staging`, `dutch-lanka-prod`. Each has its own Firestore, its own PayHere merchant ID (sandbox for dev/staging, live for prod), and its own Maps API key. Flutter flavors (`dev` / `staging` / `prod`) compile against `firebase_options_*.dart` files generated by the FlutterFire CLI.

### CI/CD
GitHub repo with two workflows:

- **PR check.** On any PR: run `flutter analyze`, `flutter test`, `cd functions && npm run lint && npm test`.
- **Deploy.** On merge to `main`: deploy Cloud Functions and Firestore Rules to the staging project. A manual workflow promotes the same artifacts to prod after smoke testing. Mobile builds go to TestFlight and Play Internal Testing tracks via Fastlane.

GitHub Actions has a generous free tier for both public and private repos — fine for this scale.

### Observability
- **Crashlytics** for client crashes (free, Firebase-native).
- **Cloud Logging** for Cloud Functions (free up to 50 GiB/month).
- **Firebase Performance Monitoring** for app launch and screen render times (free).

### Backups
Firestore exports run on a weekly schedule via a Cloud Scheduler job → exports to a Cloud Storage bucket with a 90-day lifecycle policy. Restore is documented as a runbook.

---

## 10. Roadmap beyond the demo

Things deliberately deferred from v1:

- **Web admin console.** Useful when managers want a bigger screen for analytics; can be added later as a Firebase Hosting site reading the same Firestore.
- **Multi-bakery / SaaS expansion.** Out of scope per the answered question, but the data model accommodates it: introduce a `bakeryId` field on every collection and add it to the security rules.
- **Loyalty program.** A `/loyalty/{uid}` collection with point balance, plus a Cloud Function on `onOrderStatusChange == "delivered"` to award points.
- **Driver app.** Currently delivery people use the manager app in "delivery mode". A dedicated app with simplified UI is a clean future split.
- **Voice/AI ordering, scheduled deliveries, subscription cakes** — all sit cleanly on top of the current model without architectural changes.

---

## 11. Open questions for next iteration

A few decisions that the demo can punt on but production can't:

1. **Tax handling.** Sri Lanka VAT? Out of scope for the SRS but real bakeries above the threshold need it. Adds a `tax` line to the order schema and a config doc for the rate.
2. **Refund flow.** PayHere supports partial refunds via API. Worth designing the manager-side refund UI and the Cloud Function that calls PayHere's refund endpoint before going live.
3. **Cancellation policy.** Who can cancel an order, until what status, and what happens to the stock decrement? The current model assumes no cancellations after `paid`, which is probably wrong for production.
4. **Delivery zones / fees.** Currently a flat fee field. Real bakeries usually have per-zone pricing or a distance-based formula.
5. **Custom cake workflow.** SRS mentions cake text and customizations, but a real custom-cake order often needs a back-and-forth with the customer (image attachments, design approval). The current order schema doesn't model that — would need a `customizationStatus` and a messages subcollection.

Worth a short follow-up conversation to decide which of these to address before showing the demo, and which to flag as "production work" in the pitch.
