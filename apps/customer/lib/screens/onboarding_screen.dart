import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.black,
    required this.orange,
    required this.body,
  });

  final IconData icon;
  final String black;
  final String orange;
  final String body;
}

const _slides = [
  _Slide(
    icon: LucideIcons.croissant,
    black: 'Welcome',
    orange: 'to Dutch Lanka!',
    body: 'Freshly baked breads, cakes and treats — '
        'crafted in our bakery, delivered to your door.',
  ),
  _Slide(
    icon: LucideIcons.search,
    black: 'Browse our',
    orange: 'daily menu',
    body: "See what's baking today and reserve your favourites "
        'before they sell out.',
  ),
  _Slide(
    icon: LucideIcons.shopping_bag,
    black: 'Order your',
    orange: 'favourite treat',
    body: 'Pay securely and track your order — pickup or delivery, '
        'right from your phone.',
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.surface,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Center(
                      child: Icon(
                        slide.icon,
                        size: 160,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            ClipPath(
              clipper: const ScallopedClipper(direction: ScallopDirection.top),
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.xxxl,
                  Space.xl,
                  Space.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TwoToneTitle(
                      black: _slides[_index].black,
                      orange: _slides[_index].orange,
                    ),
                    const SizedBox(height: Space.lg),
                    Text(
                      _slides[_index].body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Space.xl),
                    _PageDots(count: _slides.length, index: _index),
                    const SizedBox(height: Space.xl),
                    PrimaryButton(
                      label: isLast ? 'Get Started' : 'Next',
                      onPressed: _next,
                    ),
                  ],
                ),
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
          height: 8,
          width: active ? 24 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.muted,
            borderRadius: BorderRadius.circular(AppRadius.indicator),
          ),
        );
      }),
    );
  }
}
