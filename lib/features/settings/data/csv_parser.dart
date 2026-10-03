import 'dart:convert';

import 'package:salesroot/features/settings/models/csv_import.dart';

/// Parses RFC 4180 CSV: fields are comma-separated, a quoted field may hold
/// commas, line breaks and doubled quotes, and rows end with CRLF or LF.
/// Blank lines are dropped.
List<List<String>> parseCsv(String input) {
  final text = input.startsWith('﻿') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
    } else if (char == '"' && field.isEmpty) {
      quoted = true;
    } else if (char == ',') {
      endField();
    } else if (char == '\r' || char == '\n') {
      endRow();
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
    } else {
      field.write(char);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Decodes [bytes] as UTF-8 and splits off the header row. Null when the
/// file has no header.
CsvTable? readCsvTable(String fileName, List<int> bytes) {
  final rows = parseCsv(utf8.decode(bytes, allowMalformed: true));
  if (rows.isEmpty) return null;
  final headers = [for (final h in rows.first) h.trim()];
  return CsvTable(
    fileName: fileName,
    headers: headers,
    rows: [
      for (final row in rows.skip(1))
        [for (var c = 0; c < headers.length; c++) c < row.length ? row[c] : ''],
    ],
  );
}

/// The digits that identify a Bangladeshi mobile number: the last ten, so
/// `+880 1711-234567` and `01711234567` match.
String normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}
