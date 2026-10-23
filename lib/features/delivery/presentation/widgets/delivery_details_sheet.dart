import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Snap sizes for the current-delivery details sheet (fractions of the
/// map+sheet viewport above the pinned lifecycle action).
class DeliverySheetSnaps {
  const DeliverySheetSnaps({
    required this.compact,
    required this.medium,
    required this.expanded,
    required this.initial,
  });

  final double compact;
  final double medium;
  final double expanded;
  final double initial;

  /// Viewport-aware snaps. [preferTall] raises the default for pickup/COD forms.
  factory DeliverySheetSnaps.forViewport({
    required double viewportHeight,
    required bool preferTall,
  }) {
    // Absolute minima so compact still shows handle + status chrome.
    final h = viewportHeight <= 0 ? 600.0 : viewportHeight;
    var compact = (180 / h).clamp(0.28, 0.38);
    var medium = (300 / h).clamp(0.48, 0.60);
    var expanded = ((h - 16) / h).clamp(0.84, 0.94);
    // Keep strict ordering with room for exclusive intermediate snaps.
    if (medium <= compact + 0.04) medium = compact + 0.12;
    if (expanded <= medium + 0.04) expanded = (medium + 0.20).clamp(0.0, 0.95);
    // Forms (pickup code / COD) open mid-tall so inputs aren't buried under
    // the pinned action before the driver expands.
    final formOpen = ((medium + expanded) / 2).clamp(medium, expanded - 0.02);
    final initial = preferTall ? formOpen : compact;
    return DeliverySheetSnaps(
      compact: compact,
      medium: medium,
      expanded: expanded,
      initial: initial,
    );
  }

  /// Intermediate snaps only — Flutter requires values strictly between
  /// [minChildSize] and [maxChildSize].
  List<double> get snapSizes => [medium];
}

/// Modern White bottom sheet: drag handle expands/collapses over the map.
///
/// Uses [DraggableScrollableSheet] so sheet drag and list scrolling share one
/// [ScrollController] from the builder — no nested gesture arenas.
class DeliveryDetailsSheet extends StatefulWidget {
  const DeliveryDetailsSheet({
    super.key,
    required this.snaps,
    required this.controller,
    required this.childBuilder,
    this.onSizeChanged,
  });

  final DeliverySheetSnaps snaps;
  final DraggableScrollableController controller;
  final Widget Function(BuildContext context, ScrollController scrollController)
  childBuilder;
  final ValueChanged<double>? onSizeChanged;

  @override
  State<DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

class _DeliveryDetailsSheetState extends State<DeliveryDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    final snaps = widget.snaps;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.onSizeChanged?.call(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        key: const Key('delivery_sheet'),
        controller: widget.controller,
        initialChildSize: snaps.initial,
        minChildSize: snaps.compact,
        maxChildSize: snaps.expanded,
        snap: true,
        snapSizes: snaps.snapSizes,
        // Smooth settle after drag / keyboard expand.
        shouldCloseOnMinExtent: false,
        builder: (context, scrollController) {
          return Material(
            color: DriverTokens.surface,
            elevation: 12,
            shadowColor: Colors.black26,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.childBuilder(context, scrollController),
          );
        },
      ),
    );
  }
}

/// Drag affordance at the top of [DeliveryDetailsSheet].
class DeliverySheetHandle extends StatelessWidget {
  const DeliverySheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('delivery_sheet_handle'),
      label: 'Sheet',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: DriverTokens.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
