import 'dart:io';

/// Čita `KLJUČ=vrednost` linije iz `.env` fajla (komentari sa `#` se preskaču).
Map<String, String> readEnvFile(File file) {
  if (!file.existsSync()) return const {};
  return {
    for (final line in file.readAsLinesSync())
      if (line.indexOf('=') case final split
          when split > 0 && !line.trimLeft().startsWith('#'))
        line.substring(0, split).trim(): _unquoted(
          line.substring(split + 1).trim(),
        ),
  };
}

String _unquoted(String value) =>
    value.length > 1 &&
        (value[0] == '"' || value[0] == "'") &&
        value.endsWith(value[0])
    ? value.substring(1, value.length - 1)
    : value;

/// `.env` iz najbližeg roditeljskog foldera, a promenljive okruženja imaju
/// prednost (tako ih zadaje Docker Compose).
Map<String, String> serverEnvironment() => {
  ...readEnvFile(_envFile(Directory.current.absolute)),
  ...Platform.environment,
};

File _envFile(Directory directory) {
  final file = File('${directory.path}${Platform.pathSeparator}.env');
  final parent = directory.parent;
  if (file.existsSync() ||
      _isWorkspaceRoot(directory) ||
      parent.path == directory.path) {
    return file;
  }
  return _envFile(parent);
}

bool _isWorkspaceRoot(Directory directory) {
  final pubspec = File(
    '${directory.path}${Platform.pathSeparator}pubspec.yaml',
  );
  return pubspec.existsSync() &&
      pubspec.readAsLinesSync().any((line) => line.startsWith('workspace:'));
}
