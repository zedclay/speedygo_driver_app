import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Numeric PIN-style input (LTR digits, wide letter-spacing). Shared by the
/// pickup handoff code field. Value is owned by the caller and never logged.
class PinCodeField extends StatefulWidget {
  const PinCodeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.label,
    this.hint,
    this.helper,
    this.length = 4,
    this.autofocus = false,
    this.fieldKey,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String label;
  final String? hint;
  final String? helper;
  final int length;
  final bool autofocus;
  final Key? fieldKey;

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant PinCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DriverTokens.spaceSm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: widget.length,
            obscureText: false,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DriverTokens.spaceLg,
                vertical: 18,
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            widget.helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
