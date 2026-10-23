import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Smooth slide-to-confirm for go-online / go-offline.
///
/// Visual progress (0 = rest, 1 = completed gesture) is independent of the
/// Backend-confirmed availability shown outside this control.
///
/// Prior roughness came from resetting progress on parent/`busy` rebuilds,
/// hard-snapping to rest with no spring, and full-track tap completing the
/// action. This control follows the finger with no easing while dragging and
/// springs only after release.
class AvailabilitySlideControl extends StatefulWidget {
  const AvailabilitySlideControl({
    super.key,
    required this.label,
    required this.pendingLabel,
    required this.onConfirmed,
    required this.onlineMode,
    this.enabled = true,
    this.busy = false,
    this.completionThreshold = 0.80,
    this.semanticActionLabel,
  });

  /// True when the driver is already online (slide toward go-offline).
  final bool onlineMode;
  final String label;
  final String pendingLabel;
  final VoidCallback onConfirmed;
  final bool enabled;
  final bool busy;
  final double completionThreshold;

  /// Spoken action for assistive tech (e.g. “Passer en ligne”).
  final String? semanticActionLabel;

  @override
  State<AvailabilitySlideControl> createState() =>
      AvailabilitySlideControlState();
}

@visibleForTesting
class AvailabilitySlideControlState extends State<AvailabilitySlideControl>
    with SingleTickerProviderStateMixin {
  static const double thumbSize = 40;
  static const double trackHeight = 48;
  static const double trackPad = 4;

  late final AnimationController _controller;
  double _progress = 0;
  bool _dragging = false;
  bool _actionFired = false;
  double _trackWidth = 0;

  double get progress => _progress;

  double get _maxTravel =>
      (_trackWidth - thumbSize - trackPad * 2).clamp(0.0, 9999.0);

  bool get _canInteract => widget.enabled && !widget.busy && !_actionFired;

  double _thumbLeft(double maxTravel, TextDirection direction) {
    final rtl = direction == TextDirection.rtl;
    if (widget.onlineMode) {
      if (rtl) return trackPad + _progress * maxTravel;
      return trackPad + (1 - _progress) * maxTravel;
    }
    if (rtl) return trackPad + (1 - _progress) * maxTravel;
    return trackPad + _progress * maxTravel;
  }

  double _progressDeltaForDx(double dx, TextDirection direction) {
    final max = _maxTravel;
    if (max <= 0) return 0;
    final rtl = direction == TextDirection.rtl;
    if (widget.onlineMode) {
      final towardConfirm = rtl ? dx : -dx;
      return towardConfirm / max;
    }
    final towardConfirm = rtl ? -dx : dx;
    return towardConfirm / max;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (!mounted || _dragging) return;
    setState(() => _progress = _controller.value.clamp(0.0, 1.0));
  }

  @override
  void didUpdateWidget(covariant AvailabilitySlideControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onlineMode != widget.onlineMode) {
      _stopSpring();
      _actionFired = false;
      _progress = 0;
      _controller.value = 0;
      return;
    }
    if (oldWidget.busy && !widget.busy && _actionFired) {
      // Same confirmed mode after busy cleared → request failed.
      _actionFired = false;
      _settleTo(0, velocity: -1.2);
      return;
    }
    if (!oldWidget.busy && widget.busy && _actionFired && _progress < 0.95) {
      _settleTo(1, velocity: 0.8);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _stopSpring() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  void _settleTo(double target, {required double velocity}) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final clamped = target.clamp(0.0, 1.0);
    if (reduced) {
      setState(() {
        _progress = clamped;
        _controller.value = clamped;
      });
      return;
    }
    _controller.value = _progress;
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 180, damping: 22),
      _progress,
      clamped,
      velocity.clamp(-3.5, 3.5),
    );
    _controller.animateWith(simulation);
  }

  void _onDragStart(DragStartDetails _) {
    if (!_canInteract) return;
    _stopSpring();
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details, TextDirection direction) {
    if (!_canInteract || !_dragging) return;
    final next = (_progress + _progressDeltaForDx(details.delta.dx, direction))
        .clamp(0.0, 1.0);
    setState(() {
      _progress = next;
      _controller.value = next;
    });
  }

  void _onDragEnd(DragEndDetails details, TextDirection direction) {
    if (!_dragging) return;
    setState(() => _dragging = false);
    final max = _maxTravel;
    var progressVelocity = 0.0;
    if (max > 0) {
      progressVelocity = _progressDeltaForDx(
        details.velocity.pixelsPerSecond.dx,
        direction,
      ).clamp(-3.5, 3.5);
    }

    final completed = _progress >= widget.completionThreshold;
    if (completed && !_actionFired && widget.enabled && !widget.busy) {
      _actionFired = true;
      // Start the request immediately; settle concurrently.
      widget.onConfirmed();
      _settleTo(1, velocity: progressVelocity.abs().clamp(0.4, 2.5));
    } else if (!_actionFired) {
      _settleTo(0, velocity: progressVelocity);
    }
  }

  void _onDragCancel() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    if (!_actionFired) {
      _settleTo(0, velocity: -0.8);
    }
  }

  void _semanticsActivate() {
    if (!_canInteract) return;
    _actionFired = true;
    widget.onConfirmed();
    _settleTo(1, velocity: 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final online = widget.onlineMode;
    // Modern White: filled primary track; white thumb in both modes.
    final trackColor = Color.lerp(
      DriverTokens.primary,
      DriverTokens.onPrimaryContainer,
      _progress * 0.12,
    )!;
    final borderColor = DriverTokens.primary;
    const thumbColor = DriverTokens.surface;
    const labelColor = DriverTokens.onPrimary;
    final showPending = widget.busy || _actionFired;
    final label = showPending ? widget.pendingLabel : widget.label;
    final chevron = online
        ? (direction == TextDirection.rtl
              ? Icons.chevron_right
              : Icons.chevron_left)
        : (direction == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right);

    return Semantics(
      container: true,
      enabled: _canInteract,
      button: true,
      label: widget.semanticActionLabel ?? widget.label,
      onTap: _canInteract ? _semanticsActivate : null,
      child: Opacity(
        opacity: widget.enabled || widget.busy ? 1 : 0.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _trackWidth = constraints.maxWidth;
            final maxTravel = _maxTravel;
            final left = _thumbLeft(maxTravel, direction);
            // Raw horizontal recognizer so vertical Home scrolling is not
            // stolen, while finger tracking stays 1:1 after the arena settles.
            return RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                HorizontalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      HorizontalDragGestureRecognizer
                    >(
                      HorizontalDragGestureRecognizer.new,
                      (HorizontalDragGestureRecognizer instance) {
                        instance.onStart = _canInteract
                            ? _onDragStart
                            : null;
                        instance.onUpdate = _canInteract
                            ? (details) => _onDragUpdate(details, direction)
                            : null;
                        instance.onEnd = (details) =>
                            _onDragEnd(details, direction);
                        instance.onCancel = _onDragCancel;
                      },
                    ),
              },
              child: SizedBox(
                height: trackHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(DriverTokens.radiusPill),
                    border: Border.all(color: borderColor),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: online ? trackPad + 8 : thumbSize + 10,
                            end: online ? thumbSize + 10 : trackPad + 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(chevron, size: 18, color: labelColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: labelColor.withValues(
                                      alpha: (1.0 - _progress * 0.25).clamp(
                                        0.55,
                                        1.0,
                                      ),
                                    ),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: left,
                        top: (trackHeight - thumbSize) / 2,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: showPending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DriverTokens.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.power_settings_new,
                                  color: DriverTokens.primary,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
