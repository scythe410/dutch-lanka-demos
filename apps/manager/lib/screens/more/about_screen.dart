import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'About', orange: 'this app'),
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
          Text(
            'Dutch Lanka — Manager console',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Run the bakery: take orders through to delivery, manage the '
            'menu and stock, and keep an eye on customer feedback.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Version 1.0.0',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
