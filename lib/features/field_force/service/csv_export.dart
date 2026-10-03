import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [rows] as a UTF-8 CSV (with a BOM, so Excel reads Bangla) and opens
/// the share sheet for it.
Future<void> shareCsv({
  required String fileName,
  required List<List<String>> rows,
  String? subject,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  final body = rows.map((row) => row.map(_cell).join(',')).join('\r\n');
  await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(body)]);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: subject,
    ),
  );
}

String _cell(String value) {
  if (!value.contains(RegExp(r'[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
