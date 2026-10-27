import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/core/utils/json_helpers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.sourceId = '',
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  final String sourceId;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read ?? this.read,
    createdAt: createdAt,
    sourceId: sourceId,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    var sourceId = jsonStr(json['sourceId']);
    final category = jsonStr(json['category']);
    if (sourceId.isEmpty && category.contains(':')) {
      sourceId = category.substring(category.indexOf(':') + 1);
    }
    var type = jsonStr(json['type']);
    if (type.isEmpty && category.contains(':')) {
      type = category.substring(0, category.indexOf(':'));
    }
    return AppNotification(
      id: jsonStr(json['id']),
      type: type,
      title: jsonStr(json['title']),
      body: jsonStr(json['body']),
      read: json['read'] == true,
      createdAt: jsonStr(json['createdAt']),
      sourceId: sourceId,
    );
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final PageInfo page;
  final int unreadCount;
}

abstract class NotificationsClient {
  Future<NotificationPage> list({int limit = 30, int offset = 0});
  Future<int> unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });
  Future<void> deactivateDeviceToken({required String token});
}

class NotificationsApi implements NotificationsClient {
  NotificationsApi({required this._dio});

  final Dio _dio;

  @override
  Future<NotificationPage> list({int limit = 30, int offset = 0}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsPath,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = asJsonMap(response.data);
      return NotificationPage(
        items: asJsonList(data['items']).map(AppNotification.fromJson).toList(),
        page: PageInfo.fromJson(data),
        unreadCount: jsonInt(data['unreadCount']),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<int> unreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCountPath,
      );
      final data = asJsonMap(response.data);
      return jsonInt(data['unreadCount']);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.post<dynamic>(ApiEndpoints.notificationReadPath(id));
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post<dynamic>(ApiEndpoints.notificationsReadAllPath);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.put<dynamic>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token, 'platform': platform},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> deactivateDeviceToken({required String token}) async {
    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }
}

class FakeNotificationsClient implements NotificationsClient {
  FakeNotificationsClient({this.items = const [], this.unread});

  List<AppNotification> items;
  int? unread;
  final List<String> markedRead = [];
  int markAllCount = 0;
  int listCalls = 0;
  Object? listError;
  Object? Function(int offset)? listErrorForOffset;
  Object? markReadError;
  Object? markAllError;
  Object? unreadError;
  bool overlapOnLoadMore = false;
  Duration Function(int callCount)? listDelayForCall;
  final registered = <String>[];
  final deactivated = <String>[];
  Set<String> conflictTokens = {};

  int get _unread => unread ?? items.where((n) => !n.read).length;

  @override
  Future<NotificationPage> list({int limit = 30, int offset = 0}) async {
    listCalls += 1;
    final delay = listDelayForCall?.call(listCalls);
    if (delay != null && delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) {
      throw listError!;
    }
    final offsetError = listErrorForOffset?.call(offset);
    if (offsetError != null) {
      throw offsetError;
    }
    final snapshot = List.of(items);
    final slice = overlapOnLoadMore && offset > 0
        ? snapshot.take(limit).toList()
        : snapshot.skip(offset).take(limit).toList();
    return NotificationPage(
      items: slice,
      page: PageInfo(total: snapshot.length, limit: limit, offset: offset),
      unreadCount: _unread,
    );
  }

  @override
  Future<int> unreadCount() async {
    if (unreadError != null) {
      throw unreadError!;
    }
    return _unread;
  }

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    if (markReadError != null) {
      throw markReadError!;
    }
    items = [for (final n in items) n.id == id ? n.copyWith(read: true) : n];
    unread = null;
  }

  @override
  Future<void> markAllRead() async {
    markAllCount += 1;
    if (markAllError != null) {
      throw markAllError!;
    }
    items = [for (final n in items) n.copyWith(read: true)];
    unread = null;
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    if (conflictTokens.contains(token)) {
      throw const ApiException(
        'Push token is registered to another account',
        code: 'NOTIFICATION_INTEGRITY_CONFLICT',
        statusCode: 409,
      );
    }
    registered.add('$platform:$token');
  }

  @override
  Future<void> deactivateDeviceToken({required String token}) async {
    deactivated.add(token);
  }
}
