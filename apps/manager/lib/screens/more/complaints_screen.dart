import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/complaints_provider.dart';

class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'Customer', orange: 'complaints'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: complaintsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Text(
              "We couldn't load complaints.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                'No complaints. Nice work!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) => _ComplaintTile(complaint: rows[i]),
          );
        },
      ),
    );
  }
}

class _ComplaintTile extends ConsumerWidget {
  const _ComplaintTile({required this.complaint});
  final Map<String, dynamic> complaint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = (complaint['subject'] as String?) ?? '(no subject)';
    final body = (complaint['body'] as String?) ?? '';
    final status = (complaint['status'] as String?) ?? 'open';
    final closed = status == 'closed';
    final createdAt = complaint['createdAt'];
    final created = createdAt is Timestamp
        ? DateFormat('d MMM, h:mm a').format(createdAt.toDate())
        : '—';
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: closed ? AppColors.surface : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.buttonPill),
                  border: closed
                      ? Border.all(color: AppColors.muted.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  closed ? 'Closed' : 'Open',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: closed ? AppColors.onSurface : AppColors.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: Space.sm),
          Text(
            created,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          if (!closed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    ref.read(closeComplaintProvider)(complaint['id'] as String),
                child: const Text(
                  'Mark resolved',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
