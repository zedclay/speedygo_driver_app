import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/profile/application/profile_providers.dart';

class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final summary = ref.watch(ratingsSummaryProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: DriverNestedAppBar(title: AppStrings.ratingsTitle),
      body: summary.when(
        loading: () => LoadingView(message: AppStrings.loading),
        error: (error, _) => ErrorRetryView(
          message: error is AppException
              ? error.message
              : AppStrings.unexpectedError,
          onRetry: () => ref.invalidate(ratingsSummaryProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            OperationalCard(
              key: const Key('ratings_card'),
              padding: const EdgeInsets.symmetric(
                vertical: DriverTokens.spaceXl,
                horizontal: DriverTokens.spaceLg,
              ),
              child: data.count == 0 || data.average == null
                  ? Column(
                      children: [
                        const Icon(
                          Icons.star_outline,
                          size: 40,
                          color: DriverTokens.outline,
                        ),
                        const SizedBox(height: DriverTokens.spaceSm),
                        Text(
                          AppStrings.ratingsNone,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: DriverTokens.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            data.average!.toStringAsFixed(1),
                            key: const Key('ratings_average'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: DriverTokens.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: DriverTokens.spaceXs),
                        Text(
                          AppStrings.ratingsAverage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DriverTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: DriverTokens.spaceSm),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: _Stars(value: data.average!),
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                        Text(
                          '${AppStrings.ratingsCount}: ${data.count}',
                          key: const Key('ratings_count'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only star row for the server-provided average (display only).
class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star
                : (value >= i - 0.5 ? Icons.star_half : Icons.star_border),
            color: DriverTokens.tertiaryContainer,
            size: 28,
          ),
      ],
    );
  }
}
