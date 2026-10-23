import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/router/driver_shell_chrome.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';

void main() {
  group('DriverShellChrome', () {
    test('roots show drawer and shell app bar', () {
      for (final path in AppRoutes.shellBranches) {
        expect(DriverShellChrome.showDrawerAccess(path), isTrue);
        expect(DriverShellChrome.showShellAppBar(path), isTrue);
        expect(
          DriverShellChrome.hideBottomNav(
            path: path,
            homeHasOffer: false,
          ),
          isFalse,
        );
      }
    });

    test('offer on home hides tabs, drawer, and shell app bar', () {
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.home,
          homeHasOffer: true,
        ),
        isTrue,
      );
      expect(
        DriverShellChrome.showDrawerAccess(
          AppRoutes.home,
          homeHasOffer: true,
        ),
        isFalse,
      );
      expect(
        DriverShellChrome.showShellAppBar(
          AppRoutes.home,
          homeHasOffer: true,
        ),
        isFalse,
      );
    });

    test('AT_PICKUP keeps tabs; confirm-pickup hides them', () {
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.currentDelivery,
          homeHasOffer: false,
          deliveryStatus: 'AT_PICKUP',
        ),
        isFalse,
      );
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.currentDelivery,
          homeHasOffer: false,
          deliveryStatus: 'AT_PICKUP',
          deliveryCanConfirmPickup: true,
        ),
        isTrue,
      );
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.currentDelivery,
          homeHasOffer: false,
          deliveryStatus: 'TO_PICKUP',
        ),
        isTrue,
      );
    });

    test('contact blocked keeps tabs; other blocked hide them', () {
      expect(
        DriverShellChrome.hideBottomNav(
          path: '${AppRoutes.blockedUnavailable}/contact?role=merchant',
          homeHasOffer: false,
        ),
        isFalse,
      );
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.blockedFor(BlockedKind.deliveryPin),
          homeHasOffer: false,
        ),
        isTrue,
      );
    });

    test('profile nested screens keep tabs without drawer', () {
      for (final path in [
        AppRoutes.vehicle,
        AppRoutes.documents,
        AppRoutes.ratings,
        AppRoutes.settings,
        AppRoutes.languageSettings,
      ]) {
        expect(DriverShellChrome.showDrawerAccess(path), isFalse);
        expect(
          DriverShellChrome.hideBottomNav(path: path, homeHasOffer: false),
          isFalse,
        );
      }
    });

    test('support keeps drawer and tabs', () {
      expect(DriverShellChrome.showDrawerAccess(AppRoutes.support), isTrue);
      expect(
        DriverShellChrome.hideBottomNav(
          path: AppRoutes.support,
          homeHasOffer: false,
        ),
        isFalse,
      );
    });
  });
}
