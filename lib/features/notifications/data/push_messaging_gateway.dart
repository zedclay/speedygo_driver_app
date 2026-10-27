import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Routing hint from a native Push payload. Never trusted for match state:
/// tapping only opens Home. Availability is never mutated from a payload.
@immutable
class PushMatchHint {
  const PushMatchHint({required this.type, this.sourceId, this.notificationId});

  final String type;
  final String? sourceId;
  final String? notificationId;

  static PushMatchHint? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type != 'MATCH_OFFER') return null;
    String? uuidOrNull(Object? v) =>
        v is String && _uuid.hasMatch(v) ? v.toLowerCase() : null;
    return PushMatchHint(
      type: type as String,
      sourceId: uuidOrNull(data['sourceId'] ?? data['offerId']),
      notificationId: uuidOrNull(data['notificationId']),
    );
  }
}

enum PushAuthorization { authorized, provisional, denied, notDetermined }

extension PushAuthorizationX on PushAuthorization {
  bool get allowsDisplay =>
      this == PushAuthorization.authorized ||
      this == PushAuthorization.provisional;
}

abstract class PushMessagingGateway {
  bool get isAvailable;
  String get platform;
  Future<PushAuthorization> authorizationStatus();
  Future<PushAuthorization> requestAuthorization();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMatchHint> get onForegroundHint;
  Stream<PushMatchHint> get onOpenedHint;
  Future<PushMatchHint?> takeInitialHint();
}

class DisabledPushMessagingGateway implements PushMessagingGateway {
  const DisabledPushMessagingGateway();

  @override
  bool get isAvailable => false;
  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  @override
  Future<PushAuthorization> authorizationStatus() async =>
      PushAuthorization.notDetermined;
  @override
  Future<PushAuthorization> requestAuthorization() async =>
      PushAuthorization.notDetermined;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushMatchHint> get onForegroundHint => const Stream.empty();
  @override
  Stream<PushMatchHint> get onOpenedHint => const Stream.empty();
  @override
  Future<PushMatchHint?> takeInitialHint() async => null;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway._();

  static PushMessagingGateway? _instance;

  /// Android-only. `google-services.json` + Gradle applicationId select the
  /// Driver Firebase app. No dart-define options — they must not override
  /// native configuration. iOS/APNs stays disabled.
  static Future<PushMessagingGateway> bootstrap() async {
    final existing = _instance;
    if (existing != null) return existing;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _instance = const DisabledPushMessagingGateway();
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      return _instance = FirebasePushMessagingGateway._();
    } catch (e) {
      debugPrint('native push disabled: Firebase init failed ($e)');
      return _instance = const DisabledPushMessagingGateway();
    }
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  bool _initialTaken = false;

  @override
  bool get isAvailable => true;

  @override
  String get platform => 'android';

  static PushAuthorization _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized => PushAuthorization.authorized,
    AuthorizationStatus.provisional => PushAuthorization.provisional,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushAuthorization.denied,
    AuthorizationStatus.notDetermined => PushAuthorization.notDetermined,
  };

  @override
  Future<PushAuthorization> authorizationStatus() async =>
      _map((await _fm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushAuthorization> requestAuthorization() async =>
      _map((await _fm.requestPermission()).authorizationStatus);

  @override
  Future<String?> getToken() => _fm.getToken();

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMatchHint> get onForegroundHint => FirebaseMessaging.onMessage
      .map((m) => PushMatchHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushMatchHint>();

  @override
  Stream<PushMatchHint> get onOpenedHint => FirebaseMessaging.onMessageOpenedApp
      .map((m) => PushMatchHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushMatchHint>();

  @override
  Future<PushMatchHint?> takeInitialHint() async {
    if (_initialTaken) return null;
    _initialTaken = true;
    final m = await _fm.getInitialMessage();
    return m == null ? null : PushMatchHint.fromData(m.data);
  }
}
