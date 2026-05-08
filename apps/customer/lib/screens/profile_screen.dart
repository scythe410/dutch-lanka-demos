import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(currentUserDocProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final doc = docAsync.valueOrNull ?? const <String, dynamic>{};
    final name = (doc['name'] as String?) ?? authUser?.displayName ?? '—';
    final email = (doc['email'] as String?) ?? authUser?.email ?? '';
    final photoUrl = doc['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'My', orange: 'profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: Space.md),
            _Avatar(photoUrl: photoUrl, name: name),
            const SizedBox(height: Space.md),
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  email,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            const SizedBox(height: Space.xl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                children: [
                  _MenuRow(
                    icon: LucideIcons.user,
                    label: 'Edit profile',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.lock,
                    label: 'Change password',
                    onTap: () => context.push('/profile/password'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.map_pin,
                    label: 'Shipping address',
                    onTap: () => context.push('/addresses'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.info,
                    label: 'About us',
                    onTap: () => context.push('/about'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.message_circle,
                    label: 'Contact us',
                    onTap: () => context.push('/contact'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.md,
                Space.xl,
                Space.xl,
              ),
              child: PrimaryButton(
                label: 'Sign Out',
                icon: LucideIcons.log_out,
                onPressed: () async {
                  await ref.read(firebaseAuthProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasUrl = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primary,
      backgroundImage: hasUrl ? NetworkImage(photoUrl!) : null,
      child: hasUrl
          ? null
          : Text(
              initial,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.onPrimary,
                  ),
            ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Material(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                IconTile(icon: icon),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(
                  LucideIcons.chevron_right,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
