import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/users_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerUsersProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'All', orange: 'customers'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: customersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load customers.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (all) {
          final filtered = _query.isEmpty
              ? all
              : all.where((u) {
                  final hay =
                      '${u['name'] ?? ''} ${u['email'] ?? ''} ${u['phone'] ?? ''}'
                          .toLowerCase();
                  return hay.contains(_query.toLowerCase());
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.lg,
                  Space.xl,
                  Space.md,
                ),
                child: AppTextField(
                  hint: 'Search by name, email, phone',
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          all.isEmpty
                              ? 'No customers yet.'
                              : 'No customers match this search.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Space.xl,
                          0,
                          Space.xl,
                          Space.xl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Space.sm),
                        itemBuilder: (_, i) =>
                            _CustomerRow(user: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] as String?) ?? '—';
    final email = (user['email'] as String?) ?? '';
    final phone = (user['phone'] as String?) ?? '';
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.user),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Text(
              phone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
