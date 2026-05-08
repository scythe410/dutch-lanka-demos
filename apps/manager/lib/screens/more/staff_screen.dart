import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/firestore_provider.dart';
import '../../providers/users_provider.dart';

const _roles = ['manager', 'staff', 'customer'];

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String? _busyUid;
  String? _error;
  String? _ok;

  Future<void> _setRole(String uid, String role) async {
    setState(() {
      _busyUid = uid;
      _error = null;
      _ok = null;
    });
    try {
      final functions = ref.read(cloudFunctionsProvider);
      await functions
          .httpsCallable('setManagerRole')
          .call({'targetUid': uid, 'role': role});
      setState(() => _ok = 'Updated role to $role.');
    } catch (e) {
      setState(() => _error = 'Could not update: $e');
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffUsersProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Staff', orange: 'access'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load staff.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (rows) {
          return ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              if (_error != null) ...[
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Space.md),
              ],
              if (_ok != null) ...[
                Text(
                  _ok!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: Space.md),
              ],
              for (final s in rows)
                _StaffRow(
                  user: s,
                  busy: _busyUid == s['uid'],
                  onSetRole: (r) =>
                      _setRole(s['uid'] as String, r),
                ),
              const SizedBox(height: Space.xl),
              Container(
                padding: const EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promote a customer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Use the Customers list to find their UID, then come back here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: Space.md),
                    _PromoteByUid(
                      onSetRole: _setRole,
                      busy: _busyUid != null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.user,
    required this.busy,
    required this.onSetRole,
  });

  final Map<String, dynamic> user;
  final bool busy;
  final ValueChanged<String> onSetRole;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] as String?) ?? '—';
    final email = (user['email'] as String?) ?? '';
    final role = (user['role'] as String?) ?? 'staff';
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const IconTile(icon: LucideIcons.shield),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: _roles.contains(role) ? role : 'staff',
              underline: const SizedBox.shrink(),
              items: [
                for (final r in _roles)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: busy ? null : (v) => v == null ? null : onSetRole(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoteByUid extends StatefulWidget {
  const _PromoteByUid({required this.onSetRole, required this.busy});
  final void Function(String uid, String role) onSetRole;
  final bool busy;

  @override
  State<_PromoteByUid> createState() => _PromoteByUidState();
}

class _PromoteByUidState extends State<_PromoteByUid> {
  final _uid = TextEditingController();
  String _role = 'staff';

  @override
  void dispose() {
    _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(controller: _uid, label: 'User UID'),
        const SizedBox(height: Space.md),
        Row(
          children: [
            DropdownButton<String>(
              value: _role,
              items: [
                for (final r in _roles)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'staff'),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.busy
                    ? null
                    : () {
                        if (_uid.text.trim().isEmpty) return;
                        widget.onSetRole(_uid.text.trim(), _role);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
