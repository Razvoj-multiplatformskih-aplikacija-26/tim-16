import 'json.dart';

final class PageRequest {
  const PageRequest({this.limit = defaultLimit, this.cursor});

  factory PageRequest.fromQuery(Map<String, String> query) {
    final rawLimit = query['limit'];
    final limit = rawLimit == null ? defaultLimit : int.tryParse(rawLimit);
    if (limit == null || limit < 1 || limit > maxLimit) {
      throw WireFormatException('Parametar "limit" mora biti između 1 i $maxLimit');
    }
    final cursor = query['cursor'];
    return PageRequest(limit: limit, cursor: cursor == null || cursor.isEmpty ? null : cursor);
  }

  static const defaultLimit = 20;
  static const maxLimit = 100;

  final int limit;
  final String? cursor;

  Map<String, String> toQuery() => {'limit': '$limit', 'cursor': ?cursor};
}

final class PageDto<T> {
  const PageDto({required this.items, this.nextCursor});

  factory PageDto.fromJson(JsonMap json, T Function(JsonMap json) decode) =>
      PageDto(items: json.readList('items', decode), nextCursor: json.readOptional<String>('nextCursor'));

  final List<T> items;
  final String? nextCursor;

  bool get isLast => nextCursor == null;

  JsonMap toJson(JsonMap Function(T item) encode) => {
    'items': [for (final item in items) encode(item)],
    'nextCursor': nextCursor,
  };
}
