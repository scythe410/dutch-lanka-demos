import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// Active orders the bakery still has work on. Excludes terminal states
/// (delivered / cancelled / refunded) so the dashboard list stays useful
/// after a busy day.
final incomingOrdersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('status', whereIn: ['paid', 'preparing'])
      .orderBy('createdAt')
      .snapshots()
      .map(_mapDocs);
});

/// All orders (newest first) for the Orders tab. Bound list size is
/// driven server-side via the index — paging is a Phase 2 concern.
final allOrdersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(_mapDocs);
});

/// Single order doc, live. Used by the order-detail screen for status
/// transitions and the driver-mode toggle.
final orderByIdProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .doc(id)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return data;
  });
});

/// Today's completed-order revenue total in LKR cents. Filters server-
/// side by `completedAt >= startOfDay` (using the field `paidAt` in our
/// schema as a proxy for "money landed today" — `deliveredAt` would
/// undercount orders the manager hasn't yet marked delivered).
final todaysSalesCentsProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .snapshots()
      .map((snap) {
    var total = 0;
    for (final d in snap.docs) {
      total += (d.data()['totalCents'] as int?) ?? 0;
    }
    return total;
  });
});

final activeOrderCountProvider = StreamProvider<int>((ref) {
  final async = ref.watch(incomingOrdersProvider);
  return Stream.value(async.valueOrNull?.length ?? 0);
});

List<Map<String, dynamic>> _mapDocs(QuerySnapshot<Map<String, dynamic>> s) {
  return s.docs.map((d) {
    final data = Map<String, dynamic>.from(d.data());
    data['id'] = d.id;
    return data;
  }).toList();
}
