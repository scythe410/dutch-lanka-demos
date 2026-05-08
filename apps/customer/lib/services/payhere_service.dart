// PayHere SDK wrapper. All money is in LKR cents up to the moment we
// hand off to PayHere — the SDK takes a 2-decimal string in LKR.
//
// CRITICAL CONTRACT (CLAUDE.md rule 2):
//   The SDK fires onCompleted / onError synchronously when the payment
//   sheet closes. THIS IS NOT AUTHORITATIVE. The order's `paymentStatus`
//   only flips to "paid" when the `payhereNotify` Cloud Function processes
//   PayHere's server-to-server callback. UI must:
//     1. Call [PayHereService.startPayment] with the payload from
//        `createOrder`.
//     2. Show "processing payment" until a Firestore listener on
//        `/orders/{id}` reports `paymentStatus == "paid"`.
//     3. Treat onCompleted as a hint only — never as confirmation.
//
// SANDBOX TEST CARDS (per https://support.payhere.lk):
//   Visa success     4916217501611292   any future expiry, CVV 123
//   MasterCard       5307732125531151   any future expiry, CVV 123
//   AMEX success     346781005510225    any future expiry, CVV 1234
//   Failure          ANY card with CVV 999
//   3DS challenge    Pass `requestNon3DS: false` to PayHere to test step-up.
//
// Local development: PayHere posts to `notify_url` server-to-server, so
// `notify_url` must be reachable from the public internet. Run
// `ngrok http 5001` and configure the merchant's `notify_url` in the
// PayHere sandbox console to point at the tunnel before testing.

import 'dart:async';

import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

/// Outcome the SDK reports back to the caller. Authoritative payment
/// status comes from the order doc, not this enum.
enum PayHereResult { sdkSuccess, sdkDismissed, sdkError }

class PayHereService {
  const PayHereService();

  /// Start the PayHere payment sheet. Returns when the sheet closes —
  /// **before** the server-side notification has been processed. The
  /// caller must wait on `/orders/{id}.paymentStatus` afterwards.
  ///
  /// [payload] is the `payherePayload` returned by `createOrder` — pass
  /// it through unchanged.
  Future<PayHereResult> startPayment(Map<String, dynamic> payload) {
    final completer = Completer<PayHereResult>();

    PayHere.startPayment(
      payload,
      (paymentId) {
        // SDK reports success — payhereNotify is the truth, not this.
        appLogger.i('PayHere SDK onCompleted: $paymentId');
        if (!completer.isCompleted) {
          completer.complete(PayHereResult.sdkSuccess);
        }
      },
      (error) {
        appLogger.w('PayHere SDK onError: $error');
        if (!completer.isCompleted) {
          completer.complete(PayHereResult.sdkError);
        }
      },
      () {
        appLogger.i('PayHere SDK onDismissed');
        if (!completer.isCompleted) {
          completer.complete(PayHereResult.sdkDismissed);
        }
      },
    );

    return completer.future;
  }
}
