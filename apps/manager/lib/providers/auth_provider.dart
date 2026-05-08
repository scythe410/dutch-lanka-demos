import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Streams the signed-in user. Emits null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

enum ManagerRole { manager, staff, unknown, customer }

ManagerRole _parseRole(Object? raw) {
  switch (raw) {
    case 'manager':
      return ManagerRole.manager;
    case 'staff':
      return ManagerRole.staff;
    case 'customer':
      return ManagerRole.customer;
    default:
      return ManagerRole.unknown;
  }
}

/// Returns the role from the signed-in user's custom claims. The custom
/// claim is the source of truth (architecture rule 3); we never read the
/// `/users/{uid}.role` mirror for authorisation decisions.
final currentRoleProvider = FutureProvider<ManagerRole>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return ManagerRole.unknown;
  final token = await user.getIdTokenResult(true);
  return _parseRole(token.claims?['role']);
});
