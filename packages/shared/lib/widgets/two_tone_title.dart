import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A two-tone title where one half is in [AppColors.onSurface] and the other
/// in [AppColors.primary]. Per design.md §3, the orange portion is always the
/// noun being celebrated.
///
/// ```
/// TwoToneTitle(black: 'Welcome', orange: 'to Dutch Lanka!')
/// ```
class TwoToneTitle extends StatelessWidget {
  const TwoToneTitle({
    super.key,
    required this.black,
    required this.orange,
    this.orangeLeads = false,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String black;
  final String orange;

  /// If true, the orange span is rendered before the black span.
  final bool orangeLeads;

  /// Defaults to `displayLarge` from the theme.
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? Theme.of(context).textTheme.displayLarge)!;
    final blackSpan = TextSpan(
      text: black,
      style: base.copyWith(color: AppColors.onSurface),
    );
    final orangeSpan = TextSpan(
      text: orange,
      style: base.copyWith(color: AppColors.primary),
    );
    final spacer = TextSpan(text: ' ', style: base);

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: base,
        children: orangeLeads
            ? [orangeSpan, spacer, blackSpan]
            : [blackSpan, spacer, orangeSpan],
      ),
    );
  }
}
