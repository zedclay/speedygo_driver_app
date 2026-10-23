import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Own rating aggregate (count/average only — no individual comments).
final ratingsSummaryProvider = FutureProvider.autoDispose<DriverRatingSummary>((
  ref,
) {
  return ref.watch(driverProfileClientProvider).ratingsSummary();
});
