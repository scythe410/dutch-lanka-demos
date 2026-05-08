import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Live list of available products, ordered by category. Filters happen
/// client-side (search / pill-row category selection) — keeps queries simple
/// and within the indexes we declared.
final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('products')
      .where('available', isEqualTo: true)
      .orderBy('category')
      .snapshots()
      .map((snap) => snap.docs.map(_docToProduct).toList());
});

final productByIdProvider =
    StreamProvider.family<Product?, String>((ref, productId) {
  return ref
      .watch(firestoreProvider)
      .collection('products')
      .doc(productId)
      .snapshots()
      .map((doc) => doc.exists ? _docToProduct(doc) : null);
});

/// Resolves a Firebase Storage path (`products/{id}/main.jpg`) to a
/// download URL. Returns null if the file is missing — callers render a
/// placeholder. Cached per-path by Riverpod.
final productImageUrlProvider =
    FutureProvider.family<String?, String>((ref, path) async {
  try {
    return await ref.watch(firebaseStorageProvider).ref(path).getDownloadURL();
  } catch (_) {
    return null;
  }
});

Product _docToProduct(DocumentSnapshot doc) {
  final data = Map<String, dynamic>.from(doc.data()! as Map);
  data['id'] = doc.id;
  // freezed Product expects ISO-string timestamps; Firestore returns Timestamp.
  for (final key in ['createdAt', 'updatedAt']) {
    final v = data[key];
    if (v is Timestamp) data[key] = v.toDate().toIso8601String();
  }
  return Product.fromJson(data);
}
