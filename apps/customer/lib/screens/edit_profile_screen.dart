import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _localPickedPath;
  String? _hydratedFor;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrateFrom(Map<String, dynamic>? doc) {
    if (doc == null) return;
    final uid = doc['uid'] as String?;
    if (uid == null || uid == _hydratedFor) return;
    _hydratedFor = uid;
    _name.text = (doc['name'] as String?) ?? '';
    _phone.text = (doc['phone'] as String?) ?? '';
  }

  Future<void> _pickAndUpload() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() => _error = null);
    final XFile? xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (xfile == null) return;
    setState(() {
      _uploading = true;
      _localPickedPath = xfile.path;
    });
    try {
      await ensureUserDoc(
        auth: ref.read(firebaseAuthProvider),
        firestore: ref.read(firestoreProvider),
      );
      final ref0 = FirebaseStorage.instance.ref('users/${user.uid}/profile.jpg');
      await ref0.putFile(File(xfile.path));
      final url = await ref0.getDownloadURL();
      await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));
      // Mirror to Firebase Auth so the displayName/photoUrl path is also
      // available offline (Order docs already snapshot a name; this just
      // means future SDK reads of `currentUser.photoURL` are fresh).
      await user.updatePhotoURL(url);
    } catch (e) {
      setState(() => _error = 'Could not upload photo: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ensureUserDoc(
        auth: ref.read(firebaseAuthProvider),
        firestore: ref.read(firestoreProvider),
      );
      await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
      }, SetOptions(merge: true));
      if (_name.text.trim().isNotEmpty) {
        await user.updateDisplayName(_name.text.trim());
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(currentUserDocProvider);
    _hydrateFrom(docAsync.valueOrNull);
    final photoUrl = docAsync.valueOrNull?['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Edit', orange: 'profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: _PhotoEditor(
                    photoUrl: photoUrl,
                    localPath: _localPickedPath,
                    busy: _uploading,
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              AppTextField(
                controller: _name,
                label: 'Full name',
                hint: 'e.g. Anuradha Perera',
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _phone,
                label: 'Phone',
                hint: '+94 7X XXX XXXX',
                keyboardType: TextInputType.phone,
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Save changes',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.photoUrl,
    required this.localPath,
    required this.busy,
  });
  final String? photoUrl;
  final String? localPath;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (localPath != null) {
      image = FileImage(File(localPath!));
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      image = NetworkImage(photoUrl!);
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: AppColors.primary,
          backgroundImage: image,
          child: image == null
              ? const Icon(LucideIcons.user,
                  size: 48, color: AppColors.onPrimary)
              : null,
        ),
        Container(
          padding: const EdgeInsets.all(Space.xs),
          decoration: const BoxDecoration(
            color: AppColors.onPrimary,
            shape: BoxShape.circle,
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  LucideIcons.camera,
                  size: 18,
                  color: AppColors.primary,
                ),
        ),
      ],
    );
  }
}
