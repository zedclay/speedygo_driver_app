/// Tolerant JSON readers shared by thin feature DTOs.
Map<String, dynamic> asJsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> asJsonList(Object? value) => value is List
    ? value
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false)
    : const <Map<String, dynamic>>[];

String jsonStr(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

String? jsonStrOrNull(Object? value) => value?.toString();

int jsonInt(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse('$value') ?? fallback;

/// Parses a page `{items,total,limit,offset}` envelope.
class PageInfo {
  const PageInfo({this.total = 0, this.limit = 0, this.offset = 0});

  final int total;
  final int limit;
  final int offset;

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
    total: jsonInt(json['total']),
    limit: jsonInt(json['limit']),
    offset: jsonInt(json['offset']),
  );

  bool hasMore(int loaded) => loaded < total;
}
