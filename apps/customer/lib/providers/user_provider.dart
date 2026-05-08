import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'products_provider.dart';

/// Live `/users/{uid}` doc for the signed-in customer. Returns the raw map
/// so screens can read partially-populated docs (e.g. before `photoUrl`
/// has been set). `null` when signed out or doc missing.
final currentUserDocProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});

/// Ensures a `/users/{uid}` doc exists for the signed-in customer with
/// the minimum-viable fields. Idempotent — `merge: true` so we don't
/// stomp on existing data. firestore.rules blocks any client-side write
/// of a `role` field; the custom claim is the truth.
Future<void> ensureUserDoc({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) async {
  final user = auth.currentUser;
  if (user == null) return;
  final docRef = firestore.collection('users').doc(user.uid);
  final snap = await docRef.get();
  if (snap.exists) return;
  await docRef.set({
    'uid': user.uid,
    'email': user.email ?? '',
    'name': user.displayName ?? (user.email?.split('@').first ?? ''),
    'emailVerified': user.emailVerified,
    'fcmTokens': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
  });
}
