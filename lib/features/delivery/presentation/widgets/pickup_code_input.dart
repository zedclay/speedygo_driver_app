import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

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
  final FocusNode _focus = FocusNode();

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
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digits = widget.value;
    return Container(
      key: const Key('pickup_code_card'),
      padding: const EdgeInsets.all(DriverTokens.spaceLg),
      decoration: BoxDecoration(
        color: DriverTokens.card,
        borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        border: Border.all(color: DriverTokens.outlineVariant),
        boxShadow: DriverTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.vpn_key_outlined,
                color: DriverTokens.primary,
                size: 20,
              ),
              const SizedBox(width: DriverTokens.spaceSm),
              Expanded(
                child: Text(
                  AppStrings.pickupCodeLabel.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: DriverTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.pickupCodeHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DriverTokens.textSecondary,
            ),
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          // Visual boxes are decoration only; the real (transparent) field
          // below owns focus, keyboard, formatters and the draft value.
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 64,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: _focus,
                        builder: (context, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              _DigitBox(
                                digit: i < digits.length ? digits[i] : null,
                                active:
                                    _focus.hasFocus &&
                                    i == digits.length.clamp(0, 3),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: TextField(
                      key: const Key('pickup_code_field'),
                      controller: _controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 4,
                      obscureText: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableInteractiveSelection: false,
                      showCursor: false,
                      cursorColor: Colors.transparent,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.pickupCodeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: DriverTokens.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit, required this.active});

  final String? digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 56,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active || digit != null
            ? DriverTokens.card
            : DriverTokens.surfaceContainer,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        border: Border.all(
          color: active ? DriverTokens.primary : DriverTokens.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: Text(
        digit ?? '',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: DriverTokens.primary,
        ),
      ),
    );
  }
}
