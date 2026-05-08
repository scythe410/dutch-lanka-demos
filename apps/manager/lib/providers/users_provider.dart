import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// All staff and manager users — used by the assign-delivery dropdown
/// on the order detail screen and the Staff management page. Customer
/// list lives in a separate provider to keep query shapes simple and
/// indexes cheap.
final staffUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .where('role', whereIn: ['manager', 'staff'])
      .snapshots()
      .map(_mapDocs);
});

/// Customer-only user list. Optional name search is applied client-side
/// because case-insensitive prefix matching across the whole users
/// collection would need a secondary search index — out of scope for MVP.
final customerUsersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .where('role', isEqualTo: 'customer')
      .snapshots()
      .map(_mapDocs);
});

List<Map<String, dynamic>> _mapDocs(QuerySnapshot<Map<String, dynamic>> s) =>
    s.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();
