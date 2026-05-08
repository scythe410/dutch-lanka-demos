import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'More', orange: 'tools'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          _Row(
            icon: LucideIcons.users,
            label: 'Customers',
            onTap: () => context.push('/more/customers'),
          ),
          _Row(
            icon: LucideIcons.message_circle,
            label: 'Complaints',
            onTap: () => context.push('/more/complaints'),
          ),
          _Row(
            icon: LucideIcons.shield,
            label: 'Staff',
            onTap: () => context.push('/more/staff'),
          ),
          _Row(
            icon: LucideIcons.chart_bar,
            label: 'Reports',
            onTap: () => context.push('/more/reports'),
          ),
          _Row(
            icon: LucideIcons.info,
            label: 'About',
            onTap: () => context.push('/more/about'),
          ),
          const SizedBox(height: Space.xl),
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
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
