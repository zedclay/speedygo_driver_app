import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';

/// Navigation target card with no embedded map and no maps SDK.
///
/// Shows only what the contract provides (address / coordinates / distance).
/// `url_launcher` is not a dependency, so the driver is told to copy the
/// address and open it in the maps app of their choice. When nothing is
/// provided the card honestly states that navigation is unavailable.
class ProviderNeutralNavCard extends StatelessWidget {
  const ProviderNeutralNavCard({
    super.key,
    required this.title,
    this.address,
    this.latitude,
    this.longitude,
    this.distanceMeters,
  });

  final String title;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? distanceMeters;

  bool get _hasCoords => latitude != null && longitude != null;
  bool get _hasData =>
      (address != null && address!.trim().isNotEmpty) ||
      _hasCoords ||
      distanceMeters != null;

  String? get _copyText {
    final a = address?.trim();
    if (a != null && a.isNotEmpty) return a;
    if (_hasCoords) return '$latitude, $longitude';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = _copyText;
    return OperationalCard(
      key: const Key('nav_card'),
      title: title,
      leading: const Icon(Icons.near_me_outlined, color: DriverTokens.primary),
      child: !_hasData
          ? Text(
              AppStrings.navUnavailable,
              key: const Key('nav_unavailable'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address != null && address!.trim().isNotEmpty)
                  Text(address!, style: theme.textTheme.bodyLarge),
                if (_hasCoords)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${latitude!.toStringAsFixed(5)}, '
                      '${longitude!.toStringAsFixed(5)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (distanceMeters != null)
                  Text(
                    '${AppStrings.navDistance}: '
                    '${AppStrings.formatDistanceMeters(distanceMeters!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: DriverTokens.spaceSm),
                Text(
                  AppStrings.navCopyHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DriverTokens.textSecondary,
                  ),
                ),
                if (copy != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('nav_copy'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: copy));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppStrings.navCopied)),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(AppStrings.navCopy),
                    ),
                  ),
              ],
            ),
    );
  }
}
