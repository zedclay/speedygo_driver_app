import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/support/application/support_controller.dart';

StatusTone supportTone(String status) => switch (status) {
  'RESOLVED' || 'CLOSED' => StatusTone.success,
  'WAITING_USER' => StatusTone.warning,
  _ => StatusTone.info,
};

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportControllerProvider.notifier).load();
    });
  }

  Future<void> _compose() async {
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ComposeSheet(),
    );
    if (created == null || !mounted) return;
    final ticket = await ref
        .read(supportControllerProvider.notifier)
        .create(created);
    if (ticket != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.supportSent)));
      context.push(AppRoutes.supportDetailFor(ticket.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(supportControllerProvider);
    final controller = ref.read(supportControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.supportTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('support_new'),
        onPressed: _compose,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.supportNew),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.edgeMargin,
            DriverTokens.edgeMargin,
            96,
          ),
          children: [
            if (state.status == PagedStatus.loading && state.items.isEmpty)
              LoadingView(message: AppStrings.loading),
            if (state.status == PagedStatus.error && state.items.isEmpty)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: controller.load,
                retryKey: const Key('support_retry'),
              ),
            if (state.isEmpty)
              EmptyStateView(
                title: AppStrings.supportEmpty,
                icon: Icons.support_agent,
              ),
            for (final ticket in state.items) ...[
              OperationalCard(
                key: Key('ticket_${ticket.id}'),
                title: ticket.subject ?? ticket.publicReference,
                trailing: StatusBadge(
                  label: AppStrings.supportStatusLabel(ticket.status),
                  tone: supportTone(ticket.status),
                ),
                onTap: () =>
                    context.push(AppRoutes.supportDetailFor(ticket.id)),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${ticket.publicReference} · '
                    '${formatIsoDateTime(ticket.updatedAt)}',
                  ),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
            ],
            if (state.hasMore)
              Center(
                child: TextButton(
                  onPressed: state.loadingMore ? null : controller.loadMore,
                  child: Text(AppStrings.loadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DriverTokens.edgeMargin,
        0,
        DriverTokens.edgeMargin,
        MediaQuery.viewInsetsOf(context).bottom + DriverTokens.edgeMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('support_body_field'),
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 4000,
            decoration: InputDecoration(labelText: AppStrings.supportBodyLabel),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          SizedBox(
            height: DriverTokens.actionHeight,
            child: FilledButton(
              key: const Key('support_send'),
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_controller.text.trim()),
              child: Text(AppStrings.supportSend),
            ),
          ),
        ],
      ),
    );
  }
}
