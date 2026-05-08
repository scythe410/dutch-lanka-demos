import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'products_provider.dart';

/// Streams the set of product IDs the current user has favorited. Each
/// favorite is a doc at `/users/{uid}/favorites/{productId}`. Empty set
/// when signed-out.
final favoritesProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(const <String>{});

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

/// Toggles favorite state for [productId]. No-op if signed-out.
Future<void> toggleFavorite(WidgetRef ref, String productId) async {
  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return;
  final doc = ref
      .read(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .doc(productId);
  final snap = await doc.get();
  if (snap.exists) {
    await doc.delete();
  } else {
    await doc.set({'addedAt': FieldValue.serverTimestamp()});
  }
}
