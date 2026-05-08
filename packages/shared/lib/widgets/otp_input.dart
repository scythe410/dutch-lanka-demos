import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_theme.dart';

/// Row of N digit boxes per design.md §8 `OtpInput`.
/// 56×64, cream bg, 12 radius, no resting border, 1.5 orange focused border.
/// Auto-advance on input, auto-focus-prev on backspace. Caption row below
/// with a "Recent Code" link.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.onChanged,
    this.onResend,
    this.resendLabel = 'Recent Code',
    this.helper = "Didn't receive OTP? ",
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onResend;
  final String resendLabel;
  final String helper;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Paste — distribute across boxes.
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final lastFilled = digits.length.clamp(0, widget.length) - 1;
      if (lastFilled >= 0 && lastFilled < widget.length - 1) {
        _focusNodes[lastFilled + 1].requestFocus();
      } else {
        _focusNodes[widget.length - 1].unfocus();
      }
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    widget.onChanged?.call(_value);
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      widget.onCompleted?.call(_value);
    }
  }

  KeyEventResult _onKey(int index, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                right: i == widget.length - 1 ? 0 : Space.md,
              ),
              child: _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onChanged(i, v),
                onKey: (node, event) => _onKey(i, node, event),
              ),
            );
          }),
        ),
        const SizedBox(height: Space.lg),
        if (widget.onResend != null)
          GestureDetector(
            onTap: widget.onResend,
            child: RichText(
              text: TextSpan(
                style: appTextTheme.bodySmall?.copyWith(color: AppColors.onSurface),
                children: [
                  TextSpan(text: widget.helper),
                  TextSpan(
                    text: widget.resendLabel,
                    style: appTextTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final FocusOnKeyEventCallback onKey;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: onKey,
      child: SizedBox(
        width: 56,
        height: 64,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          onChanged: onChanged,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: appTextTheme.displayLarge?.copyWith(
            fontSize: 24,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
