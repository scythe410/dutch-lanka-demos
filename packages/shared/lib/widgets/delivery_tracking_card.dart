import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import 'scalloped_clipper.dart';

/// Floating order-tracking card. design.md §8 spec:
/// orange background, scalloped top, courier name + ETA + location on the
/// left, circular phone-call button on the right. Sits above the map on
/// the order tracking screen.
class DeliveryTrackingCard extends StatelessWidget {
  const DeliveryTrackingCard({
    super.key,
    required this.courierName,
    required this.etaLabel,
    required this.locationLabel,
    this.onCallPressed,
    this.scallopedTop = true,
  });

  final String courierName;
  final String etaLabel;
  final String locationLabel;
  final VoidCallback? onCallPressed;
  final bool scallopedTop;

  static const double _scallopAmplitude = 12.0;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        scallopedTop ? Space.xl + _scallopAmplitude : Space.xl,
        Space.xl,
        Space.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _CourierDetails(
            courierName: courierName,
            etaLabel: etaLabel,
            locationLabel: locationLabel,
          )),
          const SizedBox(width: Space.lg),
          _CallButton(onPressed: onCallPressed),
        ],
      ),
    );

    final clipped = scallopedTop
        ? ClipPath(
            clipper: const ScallopedClipper(
              direction: ScallopDirection.top,
              amplitude: _scallopAmplitude,
            ),
            child: body,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: body,
          );

    return Material(
      color: Colors.transparent,
      child: clipped,
    );
  }
}

class _CourierDetails extends StatelessWidget {
  const _CourierDetails({
    required this.courierName,
    required this.etaLabel,
    required this.locationLabel,
  });

  final String courierName;
  final String etaLabel;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          courierName,
          style: text.headlineSmall?.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Food Courier',
          style: text.bodySmall?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: Space.md),
        _IconLine(icon: LucideIcons.map_pin, label: locationLabel),
        const SizedBox(height: Space.xs),
        _IconLine(icon: LucideIcons.alarm_clock, label: etaLabel),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurface),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onPressed,
      radius: 32,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.onPrimary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.phone,
          size: 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
