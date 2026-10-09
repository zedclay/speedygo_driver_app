import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/support/application/support_controller.dart';
import 'package:speedygo_driver_app/features/support/data/support_api.dart';
import 'package:speedygo_driver_app/features/support/presentation/support_screen.dart';

class SupportDetailScreen extends ConsumerStatefulWidget {
  const SupportDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportDetailScreen> createState() =>
      _SupportDetailScreenState();
}

class _SupportDetailScreenState extends ConsumerState<SupportDetailScreen> {
  final _reply = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await ref
        .read(supportControllerProvider.notifier)
        .reply(widget.ticketId, _reply.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
      if (error == null) _reply.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final detail = ref.watch(supportDetailProvider(widget.ticketId));
    final myAccountId = ref.watch(sessionControllerProvider).me?.accountId;
    final ticket = detail.asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.supportDetailTitle)),
      body: detail.when(
        loading: () => LoadingView(message: AppStrings.loading),
        error: (error, _) => ErrorRetryView(
          message: error is AppException
              ? error.message
              : AppStrings.unexpectedError,
          onRetry: () => ref.invalidate(supportDetailProvider(widget.ticketId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      data.publicReference,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                StatusBadge(
                  label: AppStrings.supportStatusLabel(data.status),
                  tone: supportTone(data.status),
                ),
              ],
            ),
            const SizedBox(height: DriverTokens.spaceMd),
            for (final message in data.messages)
              _Bubble(
                message: message,
                mine:
                    myAccountId != null &&
                    message.authorAccountId == myAccountId,
              ),
          ],
        ),
      ),
      bottomNavigationBar: ticket == null
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceSm,
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceSm +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: !ticket.canReply
                    ? InfoBanner(message: AppStrings.supportClosedNote)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_error != null)
                            InfoBanner(
                              message: _error!,
                              tone: StatusTone.danger,
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('support_reply_field'),
                                  controller: _reply,
                                  minLines: 1,
                                  maxLines: 4,
                                  maxLength: 4000,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: AppStrings.supportReplyHint,
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: DriverTokens.spaceSm),
                              IconButton.filled(
                                key: const Key('support_reply_send'),
                                onPressed:
                                    _sending || _reply.text.trim().isEmpty
                                    ? null
                                    : _send,
                                icon: const Icon(Icons.send),
                                tooltip: AppStrings.supportSend,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final SupportMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
        padding: const EdgeInsets.all(DriverTokens.spaceMd),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: mine
              ? DriverTokens.primaryContainer
              : DriverTokens.neutralContainer,
          borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mine
                  ? AppStrings.supportYou
                  : (message.displayName ?? AppStrings.supportTeam),
              style: theme.textTheme.labelSmall,
            ),
            Text(message.body),
            Text(
              formatIsoDateTime(message.createdAt),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
