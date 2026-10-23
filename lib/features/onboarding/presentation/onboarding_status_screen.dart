import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_account_exit.dart';

enum OnboardingOutcome { pending, approved, corrections }

/// Verification terminal states — final redesign 2026-10-14.
///
/// References (evidence `driver_verification_redesign_2026-10-14/reference/final/`):
/// - pending → SpeedyGo_pending_verification_timeline-5
/// - approved → SpeedyGo_driver_approval_dashboard-6
/// - corrections → Driver_document_photo_correction_screen-4
class OnboardingStatusScreen extends ConsumerStatefulWidget {
  const OnboardingStatusScreen({super.key, required this.outcome});

  final OnboardingOutcome outcome;

  @override
  ConsumerState<OnboardingStatusScreen> createState() =>
      _OnboardingStatusScreenState();
}

class _OnboardingStatusScreenState
    extends ConsumerState<OnboardingStatusScreen> {
  _GpsUi _gps = _GpsUi.unknown;
  bool _gpsChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(onboardingControllerProvider.notifier).load();
      if (widget.outcome == OnboardingOutcome.approved) {
        _probeGps();
      }
    });
  }

  Future<void> _probeGps() async {
    try {
      final source = ref.read(deviceLocationSourceProvider);
      final enabled = await source.isLocationServiceEnabled();
      final permission = await source.checkPermission();
      if (!mounted) return;
      setState(() {
        _gpsChecked = true;
        if (!enabled) {
          _gps = _GpsUi.off;
        } else if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _gps = _GpsUi.denied;
        } else if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _gps = _GpsUi.on;
        } else {
          _gps = _GpsUi.unknown;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsChecked = true;
        _gps = _GpsUi.unknown;
      });
    }
  }

  Future<void> _refresh() async {
    await ref.read(onboardingControllerProvider.notifier).load();
    if (!mounted) return;
    final me = ref.read(onboardingControllerProvider).me;
    final status = me?.verificationStatus;
    if (widget.outcome == OnboardingOutcome.pending) {
      if (status == DriverVerificationStatuses.approved) {
        context.go(AppRoutes.onboardingApproved);
      } else if (status == DriverVerificationStatuses.rejected) {
        context.go(AppRoutes.onboardingCorrections);
      }
    } else if (widget.outcome == OnboardingOutcome.corrections) {
      if (status == DriverVerificationStatuses.pendingReview) {
        context.go(AppRoutes.onboardingPending);
      } else if (status == DriverVerificationStatuses.approved) {
        context.go(AppRoutes.onboardingApproved);
      }
    }
  }

  Future<void> _exitToLogin() => confirmVerificationLogout(context, ref);

  Future<void> _resubmit() async {
    final ok = await ref.read(onboardingControllerProvider.notifier).submit();
    if (ok && mounted) context.go(AppRoutes.onboardingPending);
  }

  String get _dossierRef {
    final id = ref.read(sessionControllerProvider).me?.accountId ?? '';
    if (id.isEmpty) return '—';
    // Real account id, no invented public prefix.
    final short = id.length > 12 ? id.substring(0, 12) : id;
    return short;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(onboardingControllerProvider);
    final me = state.me;
    final loading = state.loadStatus == OnboardingLoadStatus.loading;

    return switch (widget.outcome) {
      OnboardingOutcome.pending => _PendingTimelineBody(
        me: me,
        dossierRef: _dossierRef,
        loading: loading,
        errorMessage: state.errorMessage,
        onRefresh: loading ? null : _refresh,
        onSupport: () => context.push(AppRoutes.support),
        onDisconnect: _exitToLogin,
      ),
      OnboardingOutcome.corrections => _CorrectionsTaskBody(
        me: me,
        loading: loading,
        busy: state.busy,
        errorMessage: state.errorMessage,
        onResubmit: (me != null && canSubmitVerification(me) && !state.busy)
            ? _resubmit
            : null,
        onContinueLater: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.correctionsContinueLaterHint)),
          );
          context.go(AppRoutes.support);
        },
        onReplaceIdentity: () => context.go(AppRoutes.onboardingIdentity),
        onReplaceLicense: () => context.go(AppRoutes.onboardingLicense),
        onReplaceVehicle: () => context.go(AppRoutes.onboardingVehicle),
        onReplaceProfile: () => context.go(AppRoutes.onboardingProfile),
        onBackOrExit: () => _exitToLogin(),
      ),
      OnboardingOutcome.approved => _ApprovedDashboardBody(
        me: me,
        loading: loading,
        errorMessage: state.errorMessage,
        gps: _gpsChecked ? _gps : _GpsUi.unknown,
        onEnterHome: () {
          final hasDelivery = ref
              .read(driverNavSnapshotProvider)
              .hasActiveDelivery;
          context.go(hasDelivery ? AppRoutes.currentDelivery : AppRoutes.home);
        },
        onOpenInfo: () => context.push(AppRoutes.onboardingApprovedInfo),
        onDisconnect: _exitToLogin,
      ),
    };
  }
}

enum _GpsUi { unknown, on, off, denied }

// ── Shared helpers ──────────────────────────────────────────────────────────

String _initials(String? fullName) {
  final parts = (fullName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
}

String _firstName(String? fullName) {
  final parts = (fullName ?? '').trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}

IconData _vehicleIcon(String? type) {
  switch (type) {
    case 'MOTORCYCLE':
    case 'SCOOTER':
      return Icons.two_wheeler_outlined;
    case 'CAR':
      return Icons.directions_car_outlined;
    default:
      return Icons.local_shipping_outlined;
  }
}

class _VerifyBrandBar extends StatelessWidget implements PreferredSizeWidget {
  const _VerifyBrandBar({required this.trailing});

  final Widget trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DriverTokens.surfaceContainerLowest,
      foregroundColor: DriverTokens.navy,
      elevation: 0.5,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: DriverTokens.edgeMargin,
      title: Row(
        children: [
          const Icon(
            Icons.local_shipping,
            color: DriverTokens.cobalt,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppStrings.appNameShort,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DriverTokens.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [trailing],
    );
  }
}

// ── PENDING (timeline) ──────────────────────────────────────────────────────

class _PendingTimelineBody extends StatelessWidget {
  const _PendingTimelineBody({
    required this.me,
    required this.dossierRef,
    required this.loading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onSupport,
    required this.onDisconnect,
  });

  final DriverMe? me;
  final String dossierRef;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final VoidCallback onSupport;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: DriverTokens.coolWhite,
      appBar: _VerifyBrandBar(
        trailing: TextButton.icon(
          key: const Key('status_return_to_login'),
          onPressed: onDisconnect,
          icon: const Icon(Icons.person_outline, size: 20),
          label: Text(AppStrings.disconnect),
          style: TextButton.styleFrom(foregroundColor: DriverTokens.navy),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      InfoBanner(
                        key: const Key('onboarding_error'),
                        message: errorMessage!,
                        tone: StatusTone.danger,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      AppStrings.pendingMyDossier.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.pendingTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: DriverTokens.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.pendingTrackSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DriverTokens.cobalt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.pendingStatusBandTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  AppStrings.pendingStatusBandBody,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Timeline(
                      submitted:
                          me?.verificationSubmitted == true ||
                          me?.verificationStatus == 'PENDING_REVIEW',
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.pendingDossierRefLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dossierRef,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: DriverTokens.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DriverTokens.primaryFixed.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: DriverTokens.cobalt,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.pendingReviewNote,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: DriverTokens.cobalt,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.headset_mic_outlined,
                        color: DriverTokens.navy,
                      ),
                      title: Text(
                        AppStrings.pendingNeedHelp,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: DriverTokens.navy,
                        ),
                      ),
                      trailing: TextButton(
                        key: const Key('status_contact_support'),
                        onPressed: onSupport,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppStrings.pendingContactSupport),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('onboarding_status_cta'),
                  onPressed: onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  label: Text(AppStrings.pendingRefreshCta),
                  style: FilledButton.styleFrom(
                    backgroundColor: DriverTokens.cobalt,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.submitted});

  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineStep(
          state: submitted ? _StepState.done : _StepState.todo,
          title: AppStrings.pendingTimelineSubmitted,
          subtitle: AppStrings.pendingTimelineSubmittedMeta,
          showLine: true,
          solidLine: true,
        ),
        _TimelineStep(
          state: submitted ? _StepState.active : _StepState.todo,
          title: AppStrings.pendingTimelineReview,
          badge: submitted ? AppStrings.pendingTimelineInProgress : null,
          showLine: true,
          solidLine: false,
        ),
        _TimelineStep(
          state: _StepState.locked,
          title: AppStrings.pendingTimelineActivation,
          subtitle: AppStrings.pendingTimelineAfterApproval,
          showLine: false,
        ),
      ],
    );
  }
}

enum _StepState { done, active, todo, locked }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.state,
    required this.title,
    this.subtitle,
    this.badge,
    required this.showLine,
    this.solidLine = true,
  });

  final _StepState state;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool showLine;
  final bool solidLine;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (state) {
      _StepState.done => (Icons.check, Colors.white, DriverTokens.successGreen),
      _StepState.active => (
        Icons.circle,
        DriverTokens.cobalt,
        DriverTokens.primaryFixed,
      ),
      _StepState.locked => (
        Icons.lock_outline,
        DriverTokens.outline,
        DriverTokens.surfaceContainer,
      ),
      _StepState.todo => (
        Icons.circle_outlined,
        DriverTokens.outline,
        DriverTokens.surfaceContainer,
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(
                  icon,
                  size: state == _StepState.active ? 10 : 16,
                  color: color,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: solidLine ? 2 : 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: solidLine
                        ? Container(color: DriverTokens.outlineVariant)
                        : CustomPaint(
                            painter: _DashPainter(DriverTokens.outlineVariant),
                            size: const Size(2, 40),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: state == _StepState.locked
                          ? DriverTokens.textSecondary
                          : DriverTokens.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: DriverTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DriverTokens.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: DriverTokens.cobalt,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 4),
        paint,
      );
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── APPROVED (dashboard) ────────────────────────────────────────────────────

class _ApprovedDashboardBody extends StatelessWidget {
  const _ApprovedDashboardBody({
    required this.me,
    required this.loading,
    required this.errorMessage,
    required this.gps,
    required this.onEnterHome,
    required this.onOpenInfo,
    required this.onDisconnect,
  });

  final DriverMe? me;
  final bool loading;
  final String? errorMessage;
  final _GpsUi gps;
  final VoidCallback onEnterHome;
  final VoidCallback onOpenInfo;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = me?.profileFullName?.trim();
    final first = _firstName(name);
    final vehicle = me?.activeVehicle;
    final vehicleReady = me?.vehicleComplete == true && vehicle != null;

    final (gpsLabel, gpsOk) = switch (gps) {
      _GpsUi.on => (AppStrings.approvedGpsOn, true),
      _GpsUi.off => (AppStrings.approvedGpsOff, false),
      _GpsUi.denied => (AppStrings.approvedGpsDenied, false),
      _GpsUi.unknown => (AppStrings.approvedCheckUnknown, false),
    };

    return Scaffold(
      backgroundColor: DriverTokens.coolWhite,
      appBar: _VerifyBrandBar(
        trailing: PopupMenuButton<String>(
          key: const Key('status_account_menu'),
          tooltip: AppStrings.accountMenuTooltip,
          onSelected: (v) {
            if (v == 'logout') onDisconnect();
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'logout', child: Text(AppStrings.disconnect)),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: DriverTokens.primaryFixed,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: DriverTokens.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: DriverTokens.navy),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      InfoBanner(
                        message: errorMessage!,
                        tone: StatusTone.danger,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (loading) const LinearProgressIndicator(),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DriverTokens.successGreenSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: DriverTokens.successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.approvedBadge,
                              style: const TextStyle(
                                color: DriverTokens.successGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (first.isNotEmpty)
                      Text(
                        AppStrings.approvedGreeting(first),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DriverTokens.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.approvedTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: DriverTokens.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.approvedBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusTile(
                            icon: Icons.location_on_outlined,
                            label: AppStrings.approvedCheckGps,
                            value: gpsLabel,
                            ready: gpsOk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusTile(
                            icon: Icons.wifi,
                            label: AppStrings.approvedCheckInternet,
                            value: AppStrings.approvedConnUnknown,
                            ready: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DriverTokens.cobalt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.approvedYourVehicle.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vehicle?.model.trim().isNotEmpty == true
                                      ? vehicle!.model
                                      : AppStrings.approvedVehicleNotReady,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                if (vehicle?.plateNumber.trim().isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vehicle!.plateNumber,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        color: DriverTokens.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            _vehicleIcon(vehicle?.type),
                            color: Colors.white,
                            size: 56,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: vehicleReady
                            ? DriverTokens.successGreenSoft
                            : DriverTokens.amberSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            vehicleReady
                                ? Icons.check_circle
                                : Icons.help_outline,
                            color: vehicleReady
                                ? DriverTokens.successGreen
                                : DriverTokens.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vehicleReady
                                  ? AppStrings.approvedVehicleReady
                                  : AppStrings.approvedVehicleNotReady,
                              style: TextStyle(
                                color: vehicleReady
                                    ? DriverTokens.successGreen
                                    : DriverTokens.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: DriverTokens.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: const Key('approved_my_info'),
                        onTap: onOpenInfo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DriverTokens.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                color: DriverTokens.cobalt,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppStrings.approvedMyInfo,
                                  style: const TextStyle(
                                    color: DriverTokens.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                color: DriverTokens.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding_status_cta'),
                  onPressed: onEnterHome,
                  style: FilledButton.styleFrom(
                    backgroundColor: DriverTokens.cobalt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          AppStrings.approvedCta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.ready,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DriverTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DriverTokens.cobalt, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: DriverTokens.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: DriverTokens.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ready
                      ? DriverTokens.successGreen
                      : DriverTokens.outlineVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── CORRECTIONS (task-focused) ──────────────────────────────────────────────

class _CorrectionsTaskBody extends StatelessWidget {
  const _CorrectionsTaskBody({
    required this.me,
    required this.loading,
    required this.busy,
    required this.errorMessage,
    required this.onResubmit,
    required this.onContinueLater,
    required this.onReplaceIdentity,
    required this.onReplaceLicense,
    required this.onReplaceVehicle,
    required this.onReplaceProfile,
    required this.onBackOrExit,
  });

  final DriverMe? me;
  final bool loading;
  final bool busy;
  final String? errorMessage;
  final VoidCallback? onResubmit;
  final VoidCallback onContinueLater;
  final VoidCallback onReplaceIdentity;
  final VoidCallback onReplaceLicense;
  final VoidCallback onReplaceVehicle;
  final VoidCallback onReplaceProfile;
  final VoidCallback onBackOrExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionable = <_CorrectionItem>[];
    if (me?.identityDocumentComplete != true) {
      actionable.add(
        _CorrectionItem(
          title: AppStrings.identityTitle,
          onReplace: onReplaceIdentity,
        ),
      );
    }
    if (me?.drivingLicenseComplete != true) {
      actionable.add(
        _CorrectionItem(
          title: AppStrings.licenseTitle,
          onReplace: onReplaceLicense,
        ),
      );
    }
    if (me?.vehicleComplete != true) {
      actionable.add(
        _CorrectionItem(
          title: AppStrings.vehicleFormTitle,
          onReplace: onReplaceVehicle,
          isPhoto: false,
        ),
      );
    }
    if (me?.profileComplete != true) {
      actionable.add(
        _CorrectionItem(
          title: AppStrings.onboardingStepProfile,
          onReplace: onReplaceProfile,
          isPhoto: false,
        ),
      );
    }
    // REJECTED with all flags still complete: show docs as replaceable without
    // inventing which side/field failed.
    if (actionable.isEmpty) {
      actionable.addAll([
        _CorrectionItem(
          title: AppStrings.identityTitle,
          onReplace: onReplaceIdentity,
        ),
        _CorrectionItem(
          title: AppStrings.licenseTitle,
          onReplace: onReplaceLicense,
        ),
      ]);
    }

    final transmitted = <String>[
      if (me?.profileComplete == true) AppStrings.onboardingStepProfile,
      if (me?.identityDocumentComplete == true) AppStrings.identityTitle,
      if (me?.drivingLicenseComplete == true) AppStrings.licenseTitle,
      if (me?.vehicleComplete == true) AppStrings.vehicleFormTitle,
    ];
    // Do not claim "validated" — only transmitted/complete flags.
    final todoCount = actionable.length;
    final headline = actionable.every((a) => a.isPhoto)
        ? AppStrings.correctionsHeadlinePhoto
        : AppStrings.correctionsHeadline;

    return Scaffold(
      backgroundColor: DriverTokens.coolWhite,
      appBar: AppBar(
        backgroundColor: DriverTokens.surfaceContainerLowest,
        foregroundColor: DriverTokens.navy,
        elevation: 0,
        leading: IconButton(
          key: const Key('corrections_back_exit'),
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackOrExit,
        ),
        title: Text(
          AppStrings.correctionsDossierTitle,
          style: const TextStyle(
            color: DriverTokens.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DriverTokens.amberSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppStrings.correctionsCountBadge(todoCount),
                  style: const TextStyle(
                    color: DriverTokens.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      InfoBanner(
                        key: const Key('onboarding_error'),
                        message: errorMessage!,
                        tone: StatusTone.danger,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      headline,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: DriverTokens.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.correctionsSubtitleHonest,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress: transmitted vs todo — not "AI validated".
                    _CorrectionProgress(
                      transmitted: transmitted.length,
                      todo: todoCount,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.correctionsSummary(
                        transmitted.length,
                        todoCount,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final item in actionable) ...[
                      _CorrectionPreviewCard(item: item),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DriverTokens.amberSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: DriverTokens.amber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppStrings.correctionsReasonLabel} : ${AppStrings.correctionsReasonGeneral}',
                                  style: const TextStyle(
                                    color: DriverTokens.amber,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.correctionsGuidance,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: DriverTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Tip(
                            icon: Icons.photo_camera_outlined,
                            title: AppStrings.correctionsTipSharp,
                            subtitle: AppStrings.correctionsTipSharpHint,
                          ),
                        ),
                        Expanded(
                          child: _Tip(
                            icon: Icons.wb_sunny_outlined,
                            title: AppStrings.correctionsTipLight,
                            subtitle: AppStrings.correctionsTipLightHint,
                          ),
                        ),
                        Expanded(
                          child: _Tip(
                            icon: Icons.crop_free,
                            title: AppStrings.correctionsTipFull,
                            subtitle: AppStrings.correctionsTipFullHint,
                          ),
                        ),
                      ],
                    ),
                    if (transmitted.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const Key('corrections_transmitted_section'),
                          tilePadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.check_circle,
                            color: DriverTokens.successGreen,
                          ),
                          title: Text(
                            AppStrings.correctionsSeeTransmitted(
                              transmitted.length,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: DriverTokens.navy,
                            ),
                          ),
                          children: [
                            for (final label in transmitted)
                              ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.check,
                                  color: DriverTokens.successGreen,
                                  size: 18,
                                ),
                                title: Text(label),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: DriverTokens.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: DriverTokens.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('onboarding_status_cta'),
                      onPressed: onResubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: onResubmit == null
                            ? DriverTokens.outlineVariant
                            : DriverTokens.cobalt,
                        disabledBackgroundColor: DriverTokens.outlineVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(AppStrings.correctionsCta),
                    ),
                  ),
                  TextButton(
                    key: const Key('corrections_continue_later'),
                    onPressed: onContinueLater,
                    child: Text(AppStrings.correctionsContinueLater),
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

class _CorrectionItem {
  _CorrectionItem({
    required this.title,
    required this.onReplace,
    this.isPhoto = true,
  });

  final String title;
  final VoidCallback onReplace;
  final bool isPhoto;
}

class _CorrectionProgress extends StatelessWidget {
  const _CorrectionProgress({required this.transmitted, required this.todo});

  final int transmitted;
  final int todo;

  @override
  Widget build(BuildContext context) {
    final total = (transmitted + todo).clamp(1, 100);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < transmitted
                    ? DriverTokens.successGreen
                    : DriverTokens.amber,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CorrectionPreviewCard extends StatelessWidget {
  const _CorrectionPreviewCard({required this.item});

  final _CorrectionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverTokens.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: DriverTokens.navy,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DriverTokens.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.isPhoto
                      ? Icons.badge_outlined
                      : Icons.edit_note_outlined,
                  size: 48,
                  color: DriverTokens.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.correctionsPreviewUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DriverTokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DriverTokens.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.isPhoto
                    ? AppStrings.correctionsPhotoSide
                    : AppStrings.correctionsNeedsUpdate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: item.onReplace,
              icon: Icon(
                item.isPhoto
                    ? Icons.photo_camera_outlined
                    : Icons.edit_outlined,
              ),
              label: Text(
                item.isPhoto
                    ? AppStrings.correctionsReplacePhoto
                    : AppStrings.reviewEdit,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: DriverTokens.cobalt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DriverTokens.cobalt, size: 22),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: DriverTokens.navy,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: DriverTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
