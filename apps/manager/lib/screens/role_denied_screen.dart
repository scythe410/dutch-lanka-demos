import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class RoleDeniedScreen extends ConsumerWidget {
  const RoleDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shield_off,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: Space.xl),
              Text(
                'Access denied',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.md),
              Text(
                'This account does not have a manager or staff role. '
                'Ask the bakery owner to grant access from the Staff page.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.xxl),
              PrimaryButton(
                label: 'Sign out',
                icon: LucideIcons.log_out,
                onPressed: () async {
                  await ref.read(firebaseAuthProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
