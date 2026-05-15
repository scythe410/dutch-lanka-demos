import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.headline,
    required this.accent,
    required this.body,
  });

  final IconData icon;
  final String headline;
  final String accent;
  final String body;
}

const _slides = [
  _Slide(
    icon: LucideIcons.flame,
    headline: 'BAKED AT NIGHT.',
    accent: 'DELIVERED HOT.',
    body: 'The bakery on Sri Hemananda Mawatha — hot snack boxes, '
        'lasagna trays, and patty boxes. Open for delivery from 6 PM.',
  ),
  _Slide(
    icon: LucideIcons.search,
    headline: 'BROWSE THE',
    accent: 'KITCHEN.',
    body: "See what's on tonight and reserve your favourites before "
        'they sell out.',
  ),
  _Slide(
    icon: LucideIcons.shopping_bag,
    headline: 'ORDER &',
    accent: 'TRACK.',
    body: 'Pay securely via card, eZ Cash, mCash, Genie or FriMi — '
        'then watch your delivery come to you live.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero icon area ───────────────────────────────────
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.65,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _slides[i].icon,
                        size: 130,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Serrated yellow divider ──────────────────────────
            const SerratedEdge(color: AppColors.primary),

            // ── Content ──────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.xl,
                Space.xl,
                Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  Text(
                    'Galle · Bataganvila',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 2.0,
                        ),
                  ),
                  const SizedBox(height: Space.md),

                  // Two-tone headline
                  TwoToneTitle(
                    black: _slides[_index].headline,
                    orange: _slides[_index].accent,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 36,
                          height: 1.0,
                        ),
                  ),

                  const SizedBox(height: Space.md),

                  Text(
                    _slides[_index].body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: Space.xl),

                  _PageDots(count: _slides.length, index: _index),

                  const SizedBox(height: Space.xl),

                  PrimaryButton(
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: _next,
                  ),

                  const SizedBox(height: Space.md),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Already a regular? Sign in',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: Space.xs),
          height: 4,
          width: active ? 20 : 4,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.textTertiary,
            borderRadius: BorderRadius.circular(AppRadius.indicator),
          ),
        );
      }),
    );
  }
}
