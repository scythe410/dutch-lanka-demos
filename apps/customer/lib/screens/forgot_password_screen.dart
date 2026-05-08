import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not send reset email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: _sent ? _buildSent(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TwoToneTitle(black: 'Reset your', orange: 'password'),
        const SizedBox(height: Space.sm),
        Text(
          'Enter your email and we\'ll send you a link to set a new one.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Space.xxl),
        AppTextField(
          controller: _email,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: _error,
        ),
        const SizedBox(height: Space.xl),
        PrimaryButton(
          label: _busy ? 'Sending…' : 'Send reset link',
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: Space.lg),
        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to log in'),
          ),
        ),
      ],
    );
  }

  Widget _buildSent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TwoToneTitle(black: 'Check your', orange: 'inbox'),
        const SizedBox(height: Space.sm),
        Text(
          'We sent a reset link to ${_email.text.trim()}. '
          'If it doesn\'t appear in a minute, check your spam folder.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Space.xxl),
        PrimaryButton(
          label: 'Back to log in',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: Space.lg),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Resend email'),
          ),
        ),
      ],
    );
  }
}
