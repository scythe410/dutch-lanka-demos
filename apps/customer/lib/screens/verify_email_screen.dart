import 'dart:async';

import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.pollingEnabled = true});

  /// Allows widget tests to disable the periodic `user.reload()` poll.
  final bool pollingEnabled;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _resending = false;
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    if (widget.pollingEnabled) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkVerified(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await user.reload();
    if (user.emailVerified && mounted) {
      _pollTimer?.cancel();
      context.go('/home');
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendMessage = null;
    });
    try {
      await ref.read(firebaseAuthProvider).currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() => _resendMessage = 'Verification email sent.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _resendMessage = e.message ?? 'Could not resend email.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    // Router redirect picks it up.
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(firebaseAuthProvider).currentUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TwoToneTitle(black: 'Verify your', orange: 'email'),
              const SizedBox(height: Space.sm),
              Text(
                "We sent a verification link to:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.sm),
              Text(
                email,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: Space.lg),
              Text(
                'Open your inbox and tap the link. We will continue '
                'automatically once your email is verified.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: "I've verified my email",
                onPressed: _checkVerified,
              ),
              const SizedBox(height: Space.lg),
              Center(
                child: GestureDetector(
                  onTap: _resending ? null : _resend,
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(text: "Didn't receive it? "),
                        TextSpan(
                          text: _resending ? 'Sending…' : 'Resend email',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_resendMessage != null) ...[
                const SizedBox(height: Space.sm),
                Center(
                  child: Text(
                    _resendMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: Space.xxl),
              Center(
                child: TextButton(
                  onPressed: _signOut,
                  child: const Text('Use a different account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
