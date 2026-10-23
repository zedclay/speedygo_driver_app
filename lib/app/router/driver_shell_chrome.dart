import 'package:speedygo_driver_app/core/constants/app_constants.dart';

/// Which shell chrome to show for the Modern White navigation matrix.
///
/// Tab-bearing nested screens keep [StatefulShellRoute] bottom nav.
/// Focused screens (offer, most delivery stages, PIN/failure, details) hide it.
class DriverShellChrome {
  DriverShellChrome._();

  static bool isBranchRoot(String path) {
    final p = _pathOnly(path);
    return p == AppRoutes.home ||
        p == AppRoutes.history ||
        p == AppRoutes.earnings ||
        p == AppRoutes.profile;
  }

  /// Roots (01, 02, 16, 18, 20) plus Support (26) keep the hamburger drawer.
  /// Offer (03) is focused — no drawer.
  static bool showDrawerAccess(String path, {bool homeHasOffer = false}) {
    final p = _pathOnly(path);
    if (homeHasOffer && p == AppRoutes.home) return false;
    if (isBranchRoot(p)) return true;
    if (p == AppRoutes.support) return true;
    return false;
  }

  /// Shell SpeedyGo AppBar only on drawer-access surfaces; nested screens
  /// keep their own [DriverNestedAppBar] with Back.
  static bool showShellAppBar(String path, {bool homeHasOffer = false}) =>
      showDrawerAccess(path, homeHasOffer: homeHasOffer);

  /// Hide bottom tabs for focused matrix states.
  static bool hideBottomNav({
    required String path,
    required bool homeHasOffer,
    String? deliveryStatus,
    bool deliveryCanConfirmPickup = false,
  }) {
    final p = _pathOnly(path);

    // 03 — offer focused (still on /home, no tabs).
    if (homeHasOffer && p == AppRoutes.home) return true;

    // 04–09, 15 — delivery: tabs only for AT_PICKUP without secure pickup UI
    // (05, 06). 07 (confirm-pickup) is focused.
    if (p == AppRoutes.currentDelivery || p.startsWith('/delivery/')) {
      if (deliveryCanConfirmPickup) return true;
      return deliveryStatus != 'AT_PICKUP';
    }

    // 10–14 — blocked: tabs only for contact (10, 11).
    if (p.startsWith('${AppRoutes.blockedUnavailable}/')) {
      final kind = p.substring(AppRoutes.blockedUnavailable.length + 1);
      final slash = kind.indexOf('/');
      final leaf = slash < 0 ? kind : kind.substring(0, slash);
      return leaf != BlockedKind.contact;
    }

    return false;
  }

  static String _pathOnly(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.path.isNotEmpty) return uri.path;
    final q = path.indexOf('?');
    return q < 0 ? path : path.substring(0, q);
  }
}
