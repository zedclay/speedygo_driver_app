import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_status_screen.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';
import 'package:speedygo_driver_app/features/support/presentation/support_screen.dart';

DriverMe _pendingMe({String name = 'Fixture Driver'}) => DriverMe(
  driverProfileExists: true,
  profileComplete: true,
  identityDocumentComplete: true,
  drivingLicenseComplete: true,
  vehicleComplete: true,
  verificationSubmitted: true,
  verificationApproved: false,
  operationalReady: false,
  matchingEligible: false,
  profileFullName: name,
  verificationStatus: 'PENDING_REVIEW',
  documents: const [
    DriverDocumentInfo(type: 'IDENTITY', present: true),
    DriverDocumentInfo(type: 'DRIVING_LICENSE', present: true),
  ],
  availability: null,
);

class _SignedIn extends SessionController {
  _SignedIn(this.accountId);
  final String accountId;

  @override
  SessionState build() => SessionState(
    status: SessionStatus.signedIn,
    me: AuthMe(accountId: accountId, status: 'ACTIVE', hasDriverProfile: true),
  );
}

class _DelayedProfileClient extends FakeDriverProfileClient {
  _DelayedProfileClient({required super.me, required this.gate});

  final Completer<void> gate;
  int getMeCalls = 0;

  @override
  Future<DriverMe> getMe() async {
    getMeCalls += 1;
    if (getMeCalls == 1) return me;
    await gate.future;
    return me;
  }
}

class _FailThenOkClient extends FakeDriverProfileClient {
  _FailThenOkClient({required super.me});

  int getMeCalls = 0;

  @override
  Future<DriverMe> getMe() async {
    getMeCalls += 1;
    if (getMeCalls == 1) return me;
    if (getMeCalls == 2) {
      throw const NetworkException('Réseau indisponible', code: 'NETWORK');
    }
    return me;
  }
}

Future<ProviderContainer> _pumpPending(
  WidgetTester tester, {
  required String accountId,
  DriverProfileClient? profile,
  String locale = 'fr',
  DriverMe? me,
}) async {
  AppStrings.bind(locale);
  final pending = me ?? _pendingMe();
  final client = profile ?? FakeDriverProfileClient(me: pending);
  final container = ProviderContainer(
    overrides: [
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      sessionControllerProvider.overrideWith(() => _SignedIn(accountId)),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      driverProfileClientProvider.overrideWithValue(client),
      driverNavSnapshotProvider.overrideWith(() => _BootPending(pending)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(localeControllerProvider.notifier).restore();

  final router = GoRouter(
    initialLocation: AppRoutes.onboardingPending,
    routes: [
      GoRoute(path: AppRoutes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, _) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPending,
        builder: (_, _) =>
            const OnboardingStatusScreen(outcome: OnboardingOutcome.pending),
      ),
      GoRoute(
        path: AppRoutes.onboardingApproved,
        builder: (_, _) =>
            const OnboardingStatusScreen(outcome: OnboardingOutcome.approved),
      ),
      GoRoute(
        path: AppRoutes.onboardingCorrections,
        builder: (_, _) => const OnboardingStatusScreen(
          outcome: OnboardingOutcome.corrections,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: Locale(locale),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

class _BootPending extends DriverBootstrapController {
  _BootPending(this.me);
  final DriverMe me;

  @override
  DriverNavSnapshot build() => DriverNavSnapshot(
    sessionStatus: SessionStatus.signedIn,
    accountStatus: 'ACTIVE',
    driverMe: me,
    resolved: true,
  );
}

void main() {
  testWidgets('pending shows timeline redesign (image 5), not hourglass hero', (
    tester,
  ) async {
    await _pumpPending(tester, accountId: 'acc-pending');
    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(find.text('MON DOSSIER'), findsOneWidget);
    expect(find.text('Actualiser le statut'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);
    expect(find.text('Contacter le support'), findsOneWidget);
    expect(find.text('Dossier envoyé'), findsOneWidget);
    expect(find.text('Vérification par l’équipe'), findsOneWidget);
    expect(find.text('Activation du compte'), findsOneWidget);
    expect(find.textContaining('#SG-'), findsNothing);
    expect(find.textContaining('Yacine'), findsNothing);
    expect(find.byIcon(Icons.hourglass_empty), findsNothing);
    expect(find.byIcon(Icons.hourglass_top), findsNothing);
    expect(find.text('Inscription livreur'), findsNothing);
  });

  testWidgets('logout cancel keeps pending session', (tester) async {
    final container = await _pumpPending(tester, accountId: 'acc-pending');
    await tester.tap(find.byKey(const Key('status_return_to_login')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.logoutConfirmTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmation_cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedIn,
    );
  });

  testWidgets('logout confirm goes to Phone', (tester) async {
    final container = await _pumpPending(tester, accountId: 'acc-pending');
    await tester.tap(find.byKey(const Key('status_return_to_login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.text('Vérification en cours'), findsNothing);
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
  });

  testWidgets('Arabic pending shows disconnect label', (tester) async {
    await _pumpPending(tester, accountId: 'acc-pending', locale: 'ar');
    expect(find.text('التحقق جارٍ'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });

  testWidgets('load after signed-out does not keep driver me', (tester) async {
    final gate = Completer<void>();
    final client = _DelayedProfileClient(me: _pendingMe(), gate: gate);
    final container = await _pumpPending(
      tester,
      accountId: 'acc-pending',
      profile: client,
    );
    final loadFuture = container
        .read(onboardingControllerProvider.notifier)
        .load();
    await tester.pump();
    await container.read(sessionControllerProvider.notifier).logout();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
    gate.complete();
    await loadFuture;
    await tester.pump();
    expect(container.read(onboardingControllerProvider).me, isNull);
  });

  testWidgets('refresh network error stays pending and can retry', (
    tester,
  ) async {
    final client = _FailThenOkClient(me: _pendingMe());
    await _pumpPending(tester, accountId: 'acc-pending', profile: client);
    await tester.tap(find.byKey(const Key('onboarding_status_cta')));
    await tester.pumpAndSettle();
    expect(find.text('Réseau indisponible'), findsOneWidget);
    expect(find.text('Vérification en cours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_status_cta')));
    await tester.pumpAndSettle();
    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(client.getMeCalls, greaterThanOrEqualTo(3));
  });

  testWidgets('corrections task UI and approved dashboard expose logout', (
    tester,
  ) async {
    AppStrings.bind('fr');
    final rejected = _pendingMe().copyWithStatus('REJECTED');
    final container = ProviderContainer(
      overrides: [
        localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: 'fr')),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        sessionControllerProvider.overrideWith(() => _SignedIn('acc-r')),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        driverProfileClientProvider.overrideWithValue(
          FakeDriverProfileClient(me: rejected),
        ),
        driverNavSnapshotProvider.overrideWith(() => _BootPending(rejected)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(localeControllerProvider.notifier).restore();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingStatusScreen(
            outcome: OnboardingOutcome.corrections,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('corrections_back_exit')), findsOneWidget);
    expect(find.text('Renvoyer mon dossier'), findsOneWidget);
    expect(find.text('Remplacer la photo'), findsWidgets);

    final approved = _pendingMe(name: 'Fixture Approved')
        .copyWithStatus('APPROVED');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ProviderScope(
          overrides: [
            driverProfileClientProvider.overrideWithValue(
              FakeDriverProfileClient(me: approved),
            ),
            driverNavSnapshotProvider.overrideWith(
              () => _BootPending(approved),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingStatusScreen(
              outcome: OnboardingOutcome.approved,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status_account_menu')), findsOneWidget);
    expect(find.textContaining('approuvé'), findsWidgets);
    expect(find.text('Accéder à l’espace livreur'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsNothing);
  });

  test('pending review routes to pending; incomplete does not', () {
    final pending = _pendingMe();
    expect(
      resolveColdStartDestination(
        sessionStatus: SessionStatus.signedIn,
        driverMe: pending,
      ),
      AppRoutes.onboardingPending,
    );
    final incomplete = DriverMe(
      driverProfileExists: true,
      profileComplete: true,
      identityDocumentComplete: false,
      drivingLicenseComplete: false,
      vehicleComplete: false,
      verificationSubmitted: false,
      verificationApproved: false,
      operationalReady: false,
      matchingEligible: false,
      verificationStatus: 'UNVERIFIED',
      availability: null,
    );
    expect(
      resolveColdStartDestination(
        sessionStatus: SessionStatus.signedIn,
        driverMe: incomplete,
      ),
      AppRoutes.onboardingIdentity,
    );
  });
}

extension on DriverMe {
  DriverMe copyWithStatus(String status) => DriverMe(
    driverProfileExists: driverProfileExists,
    profileComplete: profileComplete,
    identityDocumentComplete: identityDocumentComplete,
    drivingLicenseComplete: drivingLicenseComplete,
    vehicleComplete: vehicleComplete,
    verificationSubmitted: verificationSubmitted,
    verificationApproved: status == 'APPROVED',
    operationalReady: operationalReady,
    matchingEligible: matchingEligible,
    profileFullName: profileFullName,
    verificationStatus: status,
    documents: documents,
    vehicles: vehicles,
    availability: availability,
  );
}
