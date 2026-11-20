import 'json.dart';

String encodeTime(DateTime time) => time.toUtc().toIso8601String();

DateTime decodeTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc) {
    throw WireFormatException('Vreme "$raw" nije u obliku ISO 8601 sa zonom');
  }
  return parsed;
}

extension JsonReadTime on JsonMap {
  DateTime readTime(String key) => decodeTime(read<String>(key));

  DateTime? readOptionalTime(String key) => switch (readOptional<String>(key)) {
    null => null,
    final raw => decodeTime(raw),
  };
}
