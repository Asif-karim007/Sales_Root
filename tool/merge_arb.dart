import 'dart:convert';
import 'dart:io';

/// Merges `lib/translations/parts/<area>.<locale>.arb` into `lib/translations/app_<locale>.arb`.
/// Each feature owns one part per locale, so features never edit the same file.
void main() {
  final parts =
      Directory('lib/translations/parts')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final merged = <String, Map<String, Object?>>{};
  final owners = <String, String>{};
  var failed = false;
  for (final file in parts) {
    final name = file.uri.pathSegments.last;
    final locale = name.split('.')[1];
    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final target = merged.putIfAbsent(locale, () => {'@@locale': locale});
    for (final entry in json.entries) {
      if (entry.key.startsWith('@@')) continue;
      final owner = owners['$locale/${entry.key}'];
      if (owner != null) {
        stderr.writeln('Duplicate key "${entry.key}" in $name and $owner');
        failed = true;
      }
      owners['$locale/${entry.key}'] = name;
      target[entry.key] = entry.value;
    }
  }
  final bn = merged['bn']?.keys.where((k) => !k.startsWith('@')).toSet() ?? {};
  final en = merged['en']?.keys.where((k) => !k.startsWith('@')).toSet() ?? {};
  for (final key in bn.difference(en)) {
    stderr.writeln('Missing English for "$key"');
    failed = true;
  }
  for (final key in en.difference(bn)) {
    stderr.writeln('Missing Bangla for "$key"');
    failed = true;
  }
  if (failed) exit(1);
  const encoder = JsonEncoder.withIndent('  ');
  for (final entry in merged.entries) {
    File(
      'lib/translations/app_${entry.key}.arb',
    ).writeAsStringSync('${encoder.convert(entry.value)}\n');
  }
  stdout.writeln('Merged ${parts.length} ARB parts, ${bn.length} keys.');
}
