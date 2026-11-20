import 'dart:convert';

import 'package:contract/contract.dart';

typedef Position = ({DateTime at, String id});

String encodeCursor(Position position) => base64Url
    .encode(utf8.encode('${encodeTime(position.at)}|${position.id}'))
    .replaceAll('=', '');

Position decodeCursor(String cursor) {
  try {
    final text = utf8.decode(base64Url.decode(base64Url.normalize(cursor)));
    final split = text.indexOf('|');
    if (split < 0) throw const FormatException();
    return (at: decodeTime(text.substring(0, split)), id: text.substring(split + 1));
  } on FormatException {
    throw const WireFormatException('Neispravan kursor');
  }
}

Future<PageDto<T>> pageOf<R, T>(
  PageRequest request, {
  required Future<List<R>> Function(int limit, Position? after) fetch,
  required Position Function(R row) positionOf,
  required T Function(R row) encode,
}) async {
  final after = switch (request.cursor) {
    null => null,
    final cursor => decodeCursor(cursor),
  };
  final rows = await fetch(request.limit + 1, after);
  final hasMore = rows.length > request.limit;
  final visible = hasMore ? rows.sublist(0, request.limit) : rows;
  return PageDto(
    items: [for (final row in visible) encode(row)],
    nextCursor: hasMore ? encodeCursor(positionOf(visible.last)) : null,
  );
}
