typedef JsonMap = Map<String, Object?>;

final class WireFormatException extends FormatException {
  const WireFormatException(super.message);
}

extension JsonRead on JsonMap {
  T read<T>(String key) => switch (this[key]) {
    final T value => value,
    _ => throw WireFormatException('Polje "$key" nedostaje ili ima pogrešan tip'),
  };

  T? readOptional<T extends Object>(String key) => switch (this[key]) {
    null => null,
    final T value => value,
    _ => throw WireFormatException('Polje "$key" ima pogrešan tip'),
  };

  JsonMap readObject(String key) => read<JsonMap>(key);

  List<T> readList<T>(String key, T Function(JsonMap json) decode) => [
    for (final item in read<List<Object?>>(key))
      switch (item) {
        final JsonMap object => decode(object),
        _ => throw WireFormatException('Element liste "$key" mora biti objekat'),
      },
  ];
}

JsonMap asObject(Object? decoded) => switch (decoded) {
  final JsonMap object => object,
  _ => throw const WireFormatException('Očekivan je JSON objekat'),
};
