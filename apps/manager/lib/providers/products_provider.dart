import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// Live list of all products (managers see unavailable ones too — they
/// need to flip them on or take them off-menu).
final allProductsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('products')
      .orderBy('category')
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return data;
          }).toList());
});

final productByIdProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection('products')
      .doc(id)
      .snapshots()
      .map((d) {
    if (!d.exists) return null;
    final data = Map<String, dynamic>.from(d.data()!);
    data['id'] = d.id;
    return data;
  });
});
