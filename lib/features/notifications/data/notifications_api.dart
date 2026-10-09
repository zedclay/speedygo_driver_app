import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
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
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read ?? this.read,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: jsonStr(json['id']),
        type: jsonStr(json['type']),
        title: jsonStr(json['title']),
        body: jsonStr(json['body']),
        read: json['read'] == true,
        createdAt: jsonStr(json['createdAt']),
      );
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
}

class FakeNotificationsClient implements NotificationsClient {
  FakeNotificationsClient({this.items = const [], this.unread});

  List<AppNotification> items;
  int? unread;
  final List<String> markedRead = [];
  int markAllCount = 0;

  int get _unread => unread ?? items.where((n) => !n.read).length;

  @override
  Future<NotificationPage> list({int limit = 30, int offset = 0}) async =>
      NotificationPage(
        items: items,
        page: PageInfo(total: items.length, limit: limit, offset: offset),
        unreadCount: _unread,
      );

  @override
  Future<int> unreadCount() async => _unread;

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    items = [for (final n in items) n.id == id ? n.copyWith(read: true) : n];
    unread = null;
  }

  @override
  Future<void> markAllRead() async {
    markAllCount += 1;
    items = [for (final n in items) n.copyWith(read: true)];
    unread = null;
  }
}
