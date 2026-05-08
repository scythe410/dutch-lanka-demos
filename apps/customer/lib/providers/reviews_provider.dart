import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'products_provider.dart';

/// One-shot writer for product reviews. Rule:
/// `/products/{pid}/reviews/{rid}` — `create` requires `isCustomer()` and
/// `request.resource.data.userId == request.auth.uid`. Validation is on
/// the server; we send `userId`, `userName`, `rating`, optional `comment`,
/// and `createdAt: serverTimestamp`.
final submitReviewProvider = Provider<
    Future<void> Function({
      required String productId,
      required int rating,
      String? comment,
    })>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return ({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    if (user == null) {
      throw StateError('Not signed in.');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be 1–5.');
    }
    await firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email?.split('@').first ?? 'Customer',
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  };
});
