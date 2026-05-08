import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null || user.email == null) return;
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (_next.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      // Reauth with the current password — Firebase requires a recent
      // sign-in for `updatePassword`.
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _current.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_next.text);
      setState(() => _success = 'Password updated.');
      _current.clear();
      _next.clear();
      _confirm.clear();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanize(e.code));
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before changing your password.';
      default:
        return 'Could not update password ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Change', orange: 'password'),
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
              AppTextField(
                controller: _current,
                label: 'Current password',
                obscureText: true,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _next,
                label: 'New password',
                obscureText: true,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _confirm,
                label: 'Confirm new password',
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.md),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_success != null) ...[
                const SizedBox(height: Space.md),
                Text(
                  _success!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Update password',
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
