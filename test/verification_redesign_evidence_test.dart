import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_status_screen.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

DriverMe _me({
  required String status,
  String name = 'Fixture Driver',
  bool identity = true,
  bool license = true,
  bool vehicle = true,
}) {
  return DriverMe(
    driverProfileExists: true,
    profileComplete: true,
    identityDocumentComplete: identity,
    drivingLicenseComplete: license,
    vehicleComplete: vehicle,
    verificationSubmitted: status == 'PENDING_REVIEW' || status == 'APPROVED',
    verificationApproved: status == 'APPROVED',
    operationalReady: status == 'APPROVED',
    matchingEligible: status == 'APPROVED',
    profileFullName: name,
    verificationStatus: status,
    documents: [
      if (identity) const DriverDocumentInfo(type: 'IDENTITY', present: true),
      if (license)
        const DriverDocumentInfo(type: 'DRIVING_LICENSE', present: true),
    ],
    vehicles: vehicle
        ? const [
            DriverVehicleInfo(
              id: 'v1',
              type: 'MOTORCYCLE',
              plateNumber: '16-123-45678',
              model: 'Honda CG',
              status: 'ACTIVE',
            ),
          ]
        : const [],
    availability: null,
  );
}

class _SignedIn extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.signedIn,
    me: AuthMe(
      accountId: '01fixtureaccount',
      status: 'ACTIVE',
      hasDriverProfile: true,
    ),
  );
}

class _Boot extends DriverBootstrapController {
  _Boot(this.me);
  final DriverMe me;
  @override
  DriverNavSnapshot build() => DriverNavSnapshot(
    sessionStatus: SessionStatus.signedIn,
    accountStatus: 'ACTIVE',
    driverMe: me,
    resolved: true,
  );
}

Future<void> _pumpOutcome(
  WidgetTester tester, {
  required OnboardingOutcome outcome,
  required DriverMe me,
  required String locale,
}) async {
  AppStrings.bind(locale);
  final container = ProviderContainer(
    overrides: [
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      sessionControllerProvider.overrideWith(_SignedIn.new),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      driverProfileClientProvider.overrideWithValue(
        FakeDriverProfileClient(me: me),
      ),
      driverNavSnapshotProvider.overrideWith(() => _Boot(me)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(localeControllerProvider.notifier).restore();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        home: OnboardingStatusScreen(outcome: outcome),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('fixture_backed_device_ui: FR pending timeline (image 5)', (
    tester,
  ) async {
    await _pumpOutcome(
      tester,
      outcome: OnboardingOutcome.pending,
      me: _me(status: 'PENDING_REVIEW'),
      locale: 'fr',
    );
    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(find.text('En cours d’examen'), findsOneWidget);
    expect(find.text('Dossier envoyé'), findsOneWidget);
    expect(find.text('Actualiser le statut'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top), findsNothing);
    expect(find.textContaining('Yacine'), findsNothing);
    expect(find.textContaining('#SG-'), findsNothing);
  });

  testWidgets('fixture_backed_device_ui: FR approved dashboard (image 6)', (
    tester,
  ) async {
    await _pumpOutcome(
      tester,
      outcome: OnboardingOutcome.approved,
      me: _me(status: 'APPROVED'),
      locale: 'fr',
    );
    expect(find.text('Compte approuvé'), findsOneWidget);
    expect(find.text('Prêt pour votre première livraison ?'), findsOneWidget);
    expect(find.text('Honda CG'), findsOneWidget);
    expect(find.text('16-123-45678'), findsOneWidget);
    expect(find.text('Accéder à l’espace livreur'), findsOneWidget);
    expect(find.textContaining('Renault'), findsNothing);
  });

  testWidgets('fixture_backed_device_ui: FR corrections task (image 4)', (
    tester,
  ) async {
    await _pumpOutcome(
      tester,
      outcome: OnboardingOutcome.corrections,
      me: _me(status: 'REJECTED', license: false),
      locale: 'fr',
    );
    expect(find.text('Remplacer la photo'), findsWidgets);
    expect(find.text('Renvoyer mon dossier'), findsOneWidget);
    expect(find.text('Continuer plus tard'), findsOneWidget);
    expect(find.textContaining('floue'), findsNothing); // no fabricated reason
  });

  testWidgets('fixture_backed_device_ui: AR pending + approved labels', (
    tester,
  ) async {
    await _pumpOutcome(
      tester,
      outcome: OnboardingOutcome.pending,
      me: _me(status: 'PENDING_REVIEW'),
      locale: 'ar',
    );
    expect(find.text('التحقق جارٍ'), findsOneWidget);
    expect(find.text('تحديث الحالة'), findsOneWidget);

    await _pumpOutcome(
      tester,
      outcome: OnboardingOutcome.approved,
      me: _me(status: 'APPROVED'),
      locale: 'ar',
    );
    expect(find.text('حساب معتمد'), findsOneWidget);
    expect(find.text('الدخول إلى مساحة السائق'), findsOneWidget);
  });
}
