import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Light nested app bar (Modern White) for profile sub-screens, delivery, etc.
class DriverNestedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DriverNestedAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.subtitle,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final String? subtitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DriverTokens.surface,
      foregroundColor: DriverTokens.navy,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      title: subtitle == null
          ? Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: DriverTokens.navy,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: DriverTokens.onSurfaceVariant,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: DriverTokens.navy,
                  ),
                ),
              ],
            ),
      centerTitle: true,
      actions: actions,
    );
  }
}
