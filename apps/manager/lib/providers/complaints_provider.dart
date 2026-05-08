import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// Live complaints feed, newest first. Manager closes one by setting
/// `status` to `closed`; the rule allows staff to update status.
final complaintsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('complaints')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList());
});

final closeComplaintProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) => ref
      .read(firestoreProvider)
      .collection('complaints')
      .doc(id)
      .set({'status': 'closed', 'closedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
});
