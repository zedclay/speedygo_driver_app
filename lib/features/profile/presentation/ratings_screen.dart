import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
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
      appBar: AppBar(title: Text(AppStrings.ratingsTitle)),
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
              child: data.count == 0 || data.average == null
                  ? Text(AppStrings.ratingsNone)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.ratingsAverage,
                          style: theme.textTheme.bodySmall,
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text(
                                data.average!.toStringAsFixed(2),
                                key: const Key('ratings_average'),
                                style: theme.textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DriverTokens.spaceSm),
                        Text(
                          '${AppStrings.ratingsCount}: ${data.count}',
                          key: const Key('ratings_count'),
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
