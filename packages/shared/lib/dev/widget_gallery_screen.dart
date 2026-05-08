import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/icon_tile.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/otp_input.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_card.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/scalloped_clipper.dart';
import '../widgets/secondary_button.dart';
import '../widgets/two_tone_title.dart';

/// Visual QA gallery — every shared widget with sample props.
/// Wire as the home screen of the customer app temporarily during development.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  int _qtyCream = 1;
  int _qtyOrange = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(Space.xl),
        children: [
          _Section(
            title: 'TwoToneTitle',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TwoToneTitle(black: 'Welcome', orange: 'to Dutch Lanka!'),
                SizedBox(height: Space.md),
                TwoToneTitle(black: 'Pages', orange: 'Other', orangeLeads: true),
              ],
            ),
          ),
          _Section(
            title: 'PrimaryButton',
            child: Column(
              children: [
                PrimaryButton(label: 'Get Started', onPressed: () {}),
                const SizedBox(height: Space.md),
                PrimaryButton(
                  label: 'Next',
                  icon: LucideIcons.arrow_right,
                  onPressed: () {},
                ),
                const SizedBox(height: Space.md),
                const PrimaryButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),
          _Section(
            title: 'SecondaryButton (on cream — for QA only; really lives on orange)',
            child: SecondaryButton(label: 'Add to cart', onPressed: () {}),
          ),
          _Section(
            title: 'AppTextField',
            child: const Column(
              children: [
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  helperText: "We'll send the code to this address.",
                ),
                SizedBox(height: Space.lg),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: true,
                  errorText: 'That password is incorrect.',
                ),
              ],
            ),
          ),
          _Section(
            title: 'OtpInput (4)',
            child: OtpInput(onResend: () {}),
          ),
          _Section(
            title: 'OtpInput (6)',
            child: OtpInput(length: 6, onResend: () {}),
          ),
          _Section(
            title: 'QuantityStepper — onCream',
            child: QuantityStepper(
              value: _qtyCream,
              onChanged: (v) => setState(() => _qtyCream = v),
            ),
          ),
          _Section(
            title: 'QuantityStepper — onOrange',
            child: Container(
              padding: const EdgeInsets.all(Space.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QuantityStepper(
                value: _qtyOrange,
                onChanged: (v) => setState(() => _qtyOrange = v),
                variant: QuantityStepperVariant.onOrange,
              ),
            ),
          ),
          _Section(
            title: 'IconTile — active / inactive',
            child: Row(
              children: [
                IconTile(icon: LucideIcons.shopping_cart, onTap: () {}),
                const SizedBox(width: Space.md),
                const IconTile(icon: LucideIcons.bell, active: false),
                const SizedBox(width: Space.md),
                const IconTile(icon: LucideIcons.heart),
              ],
            ),
          ),
          _Section(
            title: 'ProductCard',
            child: SizedBox(
              width: 180,
              child: ProductCard(
                title: 'Croissant',
                priceLabel: 'LKR 350',
                rating: 4.5,
                imageWidget: Container(color: const Color(0xFFEFD9B0)),
                onTap: () {},
              ),
            ),
          ),
          _Section(
            title: 'KpiTile',
            child: Row(
              children: [
                Expanded(
                  child: KpiTile(
                    label: "Today's sales",
                    value: 'LKR 24,500',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: Space.lg),
                const Expanded(
                  child: KpiTile(label: 'Active orders', value: '12'),
                ),
              ],
            ),
          ),
          _Section(
            title: 'ScallopedClipper — top edge',
            child: ClipPath(
              clipper: const ScallopedClipper(direction: ScallopDirection.top),
              child: Container(
                height: 120,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Text(
                  'Orange below, scalloped top',
                  style: appTextTheme.titleMedium
                      ?.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ),
          ),
          _Section(
            title: 'ScallopedClipper — bottom edge',
            child: ClipPath(
              clipper: const ScallopedClipper(direction: ScallopDirection.bottom),
              child: Container(
                height: 120,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Text(
                  'Orange above, scalloped bottom',
                  style: appTextTheme.titleMedium
                      ?.copyWith(color: AppColors.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: appTextTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: Space.md),
          child,
        ],
      ),
    );
  }
}
