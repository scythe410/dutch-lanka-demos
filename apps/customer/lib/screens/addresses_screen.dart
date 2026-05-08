import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/addresses_provider.dart';
import '../widgets/address_form_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Shipping', orange: 'addresses'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: addressesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load your addresses.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.map_pin,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: Space.lg),
                    Text(
                      'No saved addresses yet.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.md),
            itemBuilder: (_, i) =>
                _AddressRow(address: addresses[i], onTap: () {
              _openSheet(context, ref, addresses[i]);
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add'),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref,
      [Address? existing]) async {
    final repo = ref.read(addressRepositoryProvider);
    if (repo == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddressFormSheet(initial: existing, repo: repo),
      ),
    );
  }
}

class _AddressRow extends ConsumerWidget {
  const _AddressRow({required this.address, required this.onTap});
  final Address address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              const IconTile(icon: LucideIcons.map_pin),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: Space.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.buttonPill,
                              ),
                            ),
                            child: Text(
                              'Default',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.onPrimary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      [
                        address.line1,
                        if (address.line2 != null && address.line2!.isNotEmpty)
                          address.line2,
                        address.city,
                        if (address.postalCode != null) address.postalCode,
                      ].whereType<String>().join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    const Icon(LucideIcons.trash_2, color: AppColors.muted),
                onPressed: () async {
                  final repo = ref.read(addressRepositoryProvider);
                  if (repo != null) await repo.delete(address.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
