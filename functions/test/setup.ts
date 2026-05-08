/**
 * Jest setup — runs before any test file is loaded so admin SDK and
 * firebase-functions/params pick up the emulator host + dummy PayHere
 * config. Without this, `defineSecret(...).value()` throws because the
 * secret is not bound at deploy time.
 */

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST ?? "localhost:8080";
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT ?? "demo-test";
process.env.GOOGLE_CLOUD_PROJECT =
  process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT;

// PayHere test fixtures. These are deliberately fake — every hash in the
// test suite is computed from this same secret so signature checks
// resolve symmetrically.
process.env.PAYHERE_MERCHANT_ID =
  process.env.PAYHERE_MERCHANT_ID ?? "test-merchant";
process.env.PAYHERE_MERCHANT_SECRET =
  process.env.PAYHERE_MERCHANT_SECRET ?? "test-secret";
process.env.PAYHERE_NOTIFY_URL =
  process.env.PAYHERE_NOTIFY_URL ?? "http://localhost/notify";
