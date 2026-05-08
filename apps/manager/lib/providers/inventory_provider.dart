import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// Open low-stock alerts (`acknowledged == false`), newest first. The
/// manager acknowledges them by tapping the row — see
/// `acknowledgeAlertProvider` below.
final lowStockAlertsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('lowStockAlerts')
      .where('acknowledged', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList());
});

final unackedAlertCountProvider = StreamProvider<int>((ref) {
  final async = ref.watch(lowStockAlertsProvider);
  return Stream.value(async.valueOrNull?.length ?? 0);
});

final acknowledgeAlertProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) => ref
      .read(firestoreProvider)
      .collection('lowStockAlerts')
      .doc(id)
      .set({'acknowledged': true, 'acknowledgedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
});
