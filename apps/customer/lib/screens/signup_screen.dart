import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Please enter your name.';
    if (!_email.text.contains('@')) return 'Please enter a valid email.';
    if (_password.text.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (_password.text != _confirm.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final v = _validate();
    if (v != null) {
      setState(() => _error = v);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(firebaseAuthProvider);
      final cred = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await cred.user?.updateDisplayName(_name.text.trim());
      await cred.user?.sendEmailVerification();
      if (mounted) context.go('/verify-email');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not create account.');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TwoToneTitle(black: 'Create your', orange: 'account'),
              const SizedBox(height: Space.sm),
              Text(
                'It only takes a minute to get started.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xxl),
              AppTextField(
                controller: _name,
                label: 'Full name',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'At least 8 characters',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _confirm,
                label: 'Confirm password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                errorText: _error,
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: _busy ? 'Creating account…' : 'Sign Up',
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: Space.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
