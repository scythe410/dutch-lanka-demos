import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_prefs_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Your', orange: 'settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          _SectionLabel(label: 'Notifications'),
          _Card(
            child: Column(
              children: [
                _SwitchRow(
                  icon: LucideIcons.bell,
                  label: 'Order updates',
                  value: prefs.orderUpdates,
                  onChanged: notifier.setOrderUpdates,
                ),
                const Divider(height: 1, color: AppColors.surface),
                _SwitchRow(
                  icon: LucideIcons.sparkles,
                  label: 'Promotions',
                  value: prefs.promotions,
                  onChanged: notifier.setPromotions,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          _SectionLabel(label: 'Language'),
          _Card(
            child: Column(
              children: [
                _LanguageRow(
                  label: 'English',
                  selected: true,
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.surface),
                _LanguageRow(
                  label: 'සිංහල (coming soon)',
                  selected: false,
                  enabled: false,
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.surface),
                _LanguageRow(
                  label: 'தமிழ் (coming soon)',
                  selected: false,
                  enabled: false,
                  onTap: () {},
                ),
              ],
            ),
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

class _SectionLabel extends StatelessWidget {
  // ignore: unused_element_parameter — `label` is required.
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, 0, 0, Space.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: child,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          IconTile(icon: icon),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected)
                const Icon(LucideIcons.check, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
