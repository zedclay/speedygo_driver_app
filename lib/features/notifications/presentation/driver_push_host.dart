import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/router/app_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/notifications/application/driver_push_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_messaging_gateway.dart';

/// Forwards session transitions to Push. MATCH_OFFER taps open Home and
/// refresh offer state without mutating availability or assignments.
class DriverPushHost extends ConsumerStatefulWidget {
  const DriverPushHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DriverPushHost> createState() => _DriverPushHostState();
}

class _DriverPushHostState extends ConsumerState<DriverPushHost> {
  var _consumeScheduled = false;

  bool _navigationReady() {
    return ref.read(sessionControllerProvider).status == SessionStatus.signedIn;
  }

  void _maybeConsumePushTap() {
    if (_consumeScheduled || !mounted) return;
    if (ref.read(driverPushControllerProvider).pendingOpen == null) return;
    if (!_navigationReady()) return;
    _consumeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeScheduled = false;
      if (!mounted || !_navigationReady()) return;
      final hint = ref
          .read(driverPushControllerProvider.notifier)
          .takePendingOpen();
      if (hint != null) unawaited(_openFromPush(hint));
    });
  }

  Future<void> _openFromPush(PushMatchHint hint) async {
    if (hint.type != 'MATCH_OFFER') return;
    await ref
        .read(driverPushControllerProvider.notifier)
        .fetchAuthoritativeOffer();
    ref.read(appRouterProvider).go(AppRoutes.home);
    try {
      await ref
          .read(driverHomeControllerProvider.notifier)
          .refresh(full: false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      driverPushControllerProvider,
      (_, _) => _maybeConsumePushTap(),
    );
    ref.listen<SessionState>(sessionControllerProvider, (prev, next) {
      ref
          .read(driverPushControllerProvider.notifier)
          .onSessionChanged(prev, next);
      _maybeConsumePushTap();
    });
    return widget.child;
  }
}
