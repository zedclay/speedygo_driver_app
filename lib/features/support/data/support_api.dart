import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/core/utils/json_helpers.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.messages = const [],
  });

  final String id;
  final String publicReference;
  final String status;
  final String? subject;
  final String createdAt;
  final String updatedAt;
  final List<SupportMessage> messages;

  /// Users cannot reply on RESOLVED / CLOSED tickets (server enforces).
  bool get canReply => status != 'RESOLVED' && status != 'CLOSED';

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: jsonStr(json['id']),
    publicReference: jsonStr(json['publicReference']),
    status: jsonStr(json['status']),
    subject: jsonStrOrNull(json['subject']),
    createdAt: jsonStr(json['createdAt']),
    updatedAt: jsonStr(json['updatedAt']),
    messages: asJsonList(json['messages'])
        .map(SupportMessage.fromJson)
        .toList(),
  );
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.authorAccountId,
    required this.body,
    required this.createdAt,
    this.displayName,
  });

  final String id;
  final String authorAccountId;
  final String body;
  final String createdAt;
  final String? displayName;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: jsonStr(json['id']),
    authorAccountId: jsonStr(json['authorAccountId']),
    body: jsonStr(json['body']),
    createdAt: jsonStr(json['createdAt']),
    displayName: jsonStrOrNull(json['displayName']),
  );
}

class SupportPage {
  const SupportPage({required this.items, required this.page});

  final List<SupportTicket> items;
  final PageInfo page;
}

abstract class SupportClient {
  Future<SupportPage> list({int limit = 30, int offset = 0});
  Future<SupportTicket> detail(String id);
  Future<SupportTicket> create(String body);
  Future<SupportMessage> reply(String id, String body);
}

class SupportApi implements SupportClient {
  SupportApi({required this._dio});

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<SupportPage> list({int limit = 30, int offset = 0}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.driverSupportPath,
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final data = asJsonMap(response.data);
        return SupportPage(
          items: asJsonList(data['items']).map(SupportTicket.fromJson).toList(),
          page: PageInfo.fromJson(data),
        );
      });

  @override
  Future<SupportTicket> detail(String id) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.driverSupportDetailPath(id),
    );
    return SupportTicket.fromJson(asJsonMap(response.data));
  });

  @override
  Future<SupportTicket> create(String body) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.driverSupportPath,
      data: {'body': body},
    );
    return SupportTicket.fromJson(asJsonMap(response.data));
  });

  @override
  Future<SupportMessage> reply(String id, String body) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.driverSupportMessagesPath(id),
      data: {'body': body},
    );
    return SupportMessage.fromJson(asJsonMap(response.data));
  });
}

class FakeSupportClient implements SupportClient {
  FakeSupportClient({List<SupportTicket>? tickets}) : tickets = tickets ?? [];

  final List<SupportTicket> tickets;
  String? lastCreateBody;
  String? lastReplyBody;

  @override
  Future<SupportPage> list({int limit = 30, int offset = 0}) async =>
      SupportPage(
        items: tickets,
        page: PageInfo(total: tickets.length, limit: limit, offset: offset),
      );

  @override
  Future<SupportTicket> detail(String id) async =>
      tickets.firstWhere((t) => t.id == id);

  @override
  Future<SupportTicket> create(String body) async {
    lastCreateBody = body;
    final ticket = SupportTicket(
      id: 'tkt-${tickets.length + 1}',
      publicReference: 'SUP-${tickets.length + 1}',
      status: 'OPEN',
      createdAt: '2026-10-09T10:00:00.000Z',
      updatedAt: '2026-10-09T10:00:00.000Z',
      messages: [
        SupportMessage(
          id: 'm1',
          authorAccountId: 'me',
          body: body,
          createdAt: '2026-10-09T10:00:00.000Z',
        ),
      ],
    );
    tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<SupportMessage> reply(String id, String body) async {
    lastReplyBody = body;
    return SupportMessage(
      id: 'm-reply',
      authorAccountId: 'me',
      body: body,
      createdAt: '2026-10-09T10:05:00.000Z',
    );
  }
}
