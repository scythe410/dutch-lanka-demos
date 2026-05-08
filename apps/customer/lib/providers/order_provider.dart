import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'products_provider.dart';

/// Region-pinned Cloud Functions client. Architecture.md §6 pins our
/// Functions to `asia-south1`; the default us-central1 instance returns
/// "function not found" against our deployed callables.
final cloudFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'asia-south1');
});

/// Result of `createOrder` — the orderId we then listen to + the payload
/// the PayHere SDK consumes verbatim.
class CreateOrderResult {
  const CreateOrderResult({required this.orderId, required this.payherePayload});
  final String orderId;
  final Map<String, dynamic> payherePayload;
}

/// Wrapper that calls the `createOrder` callable and returns a typed
/// result. The callable handles all server-side validation; on failure
/// it throws a [FirebaseFunctionsException] with a `failed-precondition`
/// or `unauthenticated` code that callers map to UI messages.
final createOrderCallableProvider = Provider<
    Future<CreateOrderResult> Function(Map<String, dynamic> data)>((ref) {
  final functions = ref.watch(cloudFunctionsProvider);
  return (Map<String, dynamic> data) async {
    final callable = functions.httpsCallable('createOrder');
    final response = await callable.call<Map<String, dynamic>>(data);
    final raw = Map<String, dynamic>.from(response.data);
    return CreateOrderResult(
      orderId: raw['orderId'] as String,
      payherePayload:
          Map<String, dynamic>.from(raw['payherePayload'] as Map),
    );
  };
});

/// Live order doc — used by the tracking screen to flip from "processing"
/// to "paid" when `payhereNotify` updates the doc server-side.
final orderByIdProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, orderId) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});

/// One courier ping. The `tracking` subcollection grows with one doc per
/// 15s heartbeat from the driver app. We only render the latest.
class CourierPing {
  const CourierPing({
    required this.lat,
    required this.lng,
    required this.recordedAt,
  });

  final double lat;
  final double lng;
  final DateTime recordedAt;
}

/// Latest courier ping for a given order. Returns `null` until the driver
/// app starts heartbeating, which lets the UI hide the courier marker
/// pre-dispatch without an extra status check.
final latestCourierPingProvider =
    StreamProvider.family<CourierPing?, String>((ref, orderId) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .doc(orderId)
      .collection('tracking')
      .orderBy('recordedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    final ts = data['recordedAt'];
    if (lat == null || lng == null) return null;
    return CourierPing(
      lat: lat,
      lng: lng,
      recordedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  });
});

/// All orders for the signed-in customer, newest first. Empty when
/// signed out (the listener never attaches).
final customerOrdersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('customerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList());
});
