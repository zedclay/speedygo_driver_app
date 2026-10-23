import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';

final driverNavSnapshotProvider =
    NotifierProvider<DriverBootstrapController, DriverNavSnapshot>(
      DriverBootstrapController.new,
    );

/// Loads `/driver/me` + current delivery after session restore / OTP.
class DriverBootstrapController extends Notifier<DriverNavSnapshot> {
  @override
  DriverNavSnapshot build() {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut ||
          next.status == SessionStatus.unknown ||
          next.status == SessionStatus.restoring ||
          next.status == SessionStatus.restoreRetryable) {
        state = DriverNavSnapshot(sessionStatus: next.status);
      } else if (next.status == SessionStatus.needsDriverProfile) {
        state = DriverNavSnapshot(
          sessionStatus: next.status,
          accountStatus: next.me?.status,
          resolved: true,
        );
      }
    });
    return const DriverNavSnapshot(sessionStatus: SessionStatus.unknown);
  }

  /// Call after [SessionController.restore] or successful OTP verify.
  Future<String> resolveAfterSession() async {
    final session = ref.read(sessionControllerProvider);
    final accountStatus = session.me?.status;

    if (session.status == SessionStatus.unknown ||
        session.status == SessionStatus.restoring ||
        session.status == SessionStatus.restoreRetryable) {
      state = DriverNavSnapshot(sessionStatus: session.status);
      return AppRoutes.splash;
    }
    if (session.status == SessionStatus.signedOut) {
      state = DriverNavSnapshot(
        sessionStatus: SessionStatus.signedOut,
        accountStatus: accountStatus,
        resolved: true,
      );
      return resolveColdStartDestination(
        sessionStatus: SessionStatus.signedOut,
        accountStatus: accountStatus,
      );
    }
    if (session.status == SessionStatus.needsDriverProfile) {
      state = DriverNavSnapshot(
        sessionStatus: SessionStatus.needsDriverProfile,
        accountStatus: accountStatus,
        resolved: true,
      );
      return resolveColdStartDestination(
        sessionStatus: SessionStatus.needsDriverProfile,
        accountStatus: accountStatus,
      );
    }

    try {
      final me = await ref.read(availabilityClientProvider).getMe();
      var hasActive = false;
      final approved =
          me.verificationStatus == DriverVerificationStatuses.approved ||
          me.verificationApproved;
      if (approved) {
        try {
          final delivery = await ref.read(deliveryClientProvider).getCurrent();
          hasActive = delivery != null && !delivery.isDelivered;
        } catch (_) {
          hasActive = false;
        }
      }
      state = DriverNavSnapshot(
        sessionStatus: SessionStatus.signedIn,
        accountStatus: accountStatus,
        driverMe: me,
        hasActiveDelivery: hasActive,
        resolved: true,
      );
      return resolveColdStartDestination(
        sessionStatus: SessionStatus.signedIn,
        accountStatus: accountStatus,
        driverMe: me,
        hasActiveDelivery: hasActive,
      );
    } on AppException catch (error) {
      if (error is ApiException && error.isAuthFailure) {
        await ref.read(sessionControllerProvider.notifier).logout();
        state = const DriverNavSnapshot(
          sessionStatus: SessionStatus.signedOut,
          resolved: true,
        );
        return AppRoutes.phone;
      }
      await ref
          .read(sessionControllerProvider.notifier)
          .markTransientRestoreFailure(
            issue: error is ApiException && error.isPermissionDenied
                ? RestoreIssue.permission
                : RestoreIssue.offline,
            message: error is NetworkException ||
                    (error is ApiException && (error.statusCode ?? 0) >= 500) ||
                    (error is ApiException && error.isPermissionDenied)
                ? null
                : error.message,
          );
      state = const DriverNavSnapshot(
        sessionStatus: SessionStatus.restoreRetryable,
      );
      return AppRoutes.splash;
    } catch (_) {
      await ref
          .read(sessionControllerProvider.notifier)
          .markTransientRestoreFailure();
      state = const DriverNavSnapshot(
        sessionStatus: SessionStatus.restoreRetryable,
      );
      return AppRoutes.splash;
    }
  }

  void markActiveDelivery(bool active) {
    if (!state.resolved) return;
    state = DriverNavSnapshot(
      sessionStatus: state.sessionStatus,
      accountStatus: state.accountStatus,
      driverMe: state.driverMe,
      hasActiveDelivery: active,
      resolved: true,
    );
  }

  void clearActiveDelivery() {
    markActiveDelivery(false);
  }

  /// Soft-refresh `/driver/me` into the nav snapshot without a full bootstrap.
  void applyDriverMe(DriverMe me) {
    if (state.sessionStatus != SessionStatus.signedIn) return;
    state = DriverNavSnapshot(
      sessionStatus: state.sessionStatus,
      accountStatus: state.accountStatus,
      driverMe: me,
      hasActiveDelivery: state.hasActiveDelivery,
      resolved: true,
    );
  }
}
