import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Manager-only login. No signup option per architecture: managers are
/// provisioned out-of-band via the `setManagerRole` Function. After a
/// successful sign-in the screen reads the user's `role` custom claim
/// and either routes to `/dashboard` (manager/staff) or `/role-denied`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // Force a token refresh so the role claim is fresh; the user's
      // claim might have been updated since their last cached token.
      final user = auth.currentUser;
      if (user == null) return;
      final token = await user.getIdTokenResult(true);
      final role = token.claims?['role'];
      if (!mounted) return;
      if (role == 'manager' || role == 'staff') {
        context.go('/dashboard');
      } else {
        context.go('/role-denied');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _humanize(e.code));
    } catch (e) {
      setState(() => _error = 'Could not sign in: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      default:
        return 'Sign-in failed ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const TwoToneTitle(
                black: 'Dutch',
                orange: 'Lanka',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Manager console',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: Space.xxl),
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'manager@dutchlanka.lk',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _password,
                label: 'Password',
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.md),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: 'Sign in',
                icon: LucideIcons.log_in,
                onPressed: _busy ? null : _signIn,
              ),
              const Spacer(),
              Text(
                'Manager accounts are provisioned by the bakery owner.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
