import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'products_provider.dart';

/// Live list of saved addresses for the signed-in user. Empty when
/// signed out (the listener never attaches).
final addressesProvider = StreamProvider<List<Address>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('addresses')
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return Address.fromJson(data);
          }).toList()
            ..sort((a, b) {
              if (a.isDefault != b.isDefault) {
                return a.isDefault ? -1 : 1;
              }
              return a.label.compareTo(b.label);
            }));
});

class AddressRepository {
  AddressRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('addresses');

  Future<String> upsert(Address address) async {
    final isNew = address.id.isEmpty;
    final ref = isNew ? _col.doc() : _col.doc(address.id);
    final data = address.toJson()..remove('id');
    await ref.set(data, SetOptions(merge: !isNew));
    return ref.id;
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Sets [id] as the default and clears `isDefault` on every other doc
  /// in a single batch so we never end up with two defaults.
  Future<void> setDefault(String id) async {
    final docs = await _col.get();
    final batch = _firestore.batch();
    for (final d in docs.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
  }
}

final addressRepositoryProvider = Provider<AddressRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return AddressRepository(ref.watch(firestoreProvider), user.uid);
});
