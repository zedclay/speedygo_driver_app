import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';

class PickupCodeInput extends StatefulWidget {
  const PickupCodeInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.autofocus = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool autofocus;

  @override
  State<PickupCodeInput> createState() => _PickupCodeInputState();
}

class _PickupCodeInputState extends State<PickupCodeInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant PickupCodeInput oldWidget) {
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
          AppStrings.pickupCodeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('pickup_code_field'),
            controller: _controller,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 4,
            obscureText: false,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: AppStrings.pickupCodeHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.pickupCodeHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
