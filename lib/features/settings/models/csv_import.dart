import 'package:salesroot/core/utils/json_fields.dart';

/// A customer field a CSV column can fill, by its `CompanyUpsert` key.
/// [aliases] are lower-case header names that map to it automatically.
enum ImportField {
  name('name', [
    'name',
    'company',
    'customer',
    'shop',
    'outlet',
    'business',
    'organisation',
    'organization',
    'নাম',
    'প্রতিষ্ঠান',
    'দোকান',
  ]),
  phone('phone', ['phone', 'mobile', 'phone number', 'cell', 'মোবাইল', 'ফোন']),
  email('email', ['email', 'e-mail', 'ইমেইল']),
  area('area', ['area', 'zone', 'thana', 'এলাকা']),
  address('address', ['address', 'ঠিকানা']),
  district('district', ['district', 'city', 'জেলা']),
  note('notes', ['note', 'notes', 'remarks', 'comment', 'নোট']),
  skip('', []);

  const ImportField(this.wire, this.aliases);

  final String wire;
  final List<String> aliases;

  static const required = [ImportField.name];

  static ImportField forHeader(String header) {
    final key = header.trim().toLowerCase();
    for (final field in values) {
      if (field.aliases.contains(key)) return field;
    }
    return ImportField.skip;
  }
}

/// A parsed CSV file: the header row and the data rows, each padded to the
/// header's width.
class CsvTable {
  const CsvTable({
    required this.fileName,
    required this.headers,
    required this.rows,
  });

  final String fileName;
  final List<String> headers;
  final List<List<String>> rows;

  /// The first non-empty value in [column], for the mapping hint.
  String sample(int column) => rows
      .map((row) => row[column].trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
}

/// What `companies/import` reports for a dry run or a committed import.
class ImportResult {
  const ImportResult({
    required this.total,
    required this.imported,
    required this.duplicates,
    required this.failed,
  });

  final int total;
  final int imported;
  final int duplicates;
  final int failed;

  /// The answer's counts; a list counts its items.
  factory ImportResult.fromJson(
    Map<String, dynamic> json, {
    required int rows,
  }) {
    int count(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is List) return value.length;
        final number = jsonInt(value);
        if (number != null) return number;
      }
      return 0;
    }

    return ImportResult(
      total: jsonInt(json['total']) ?? rows,
      imported: count(const ['created', 'imported', 'inserted', 'valid']),
      duplicates: count(const ['duplicates', 'skipped']),
      failed: count(const ['errors', 'failed', 'invalid']),
    );
  }
}
