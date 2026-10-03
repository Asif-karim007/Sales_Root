import 'package:salesroot/core/utils/json_fields.dart';

/// A lead field a CSV column can fill. [aliases] are lower-case header names
/// that map to it automatically.
enum ImportField {
  name('Name', ['name', 'lead', 'lead name', 'contact', 'নাম']),
  mobile('Mobile', ['mobile', 'phone', 'phone number', 'cell', 'মোবাইল']),
  company('Company', [
    'company',
    'organisation',
    'organization',
    'business',
    'প্রতিষ্ঠান',
  ]),
  email('Email', ['email', 'e-mail', 'ইমেইল']),
  designation('Designation', ['designation', 'title', 'পদবি']),
  stage('Stage', ['stage', 'status', 'ধাপ']),
  value('Value', ['value', 'deal value', 'amount', 'মূল্য']),
  source('Source', ['source', 'উৎস']),
  note('Note', ['note', 'notes', 'remarks', 'comment', 'নোট']),
  skip('Skip', []);

  const ImportField(this.wire, this.aliases);

  final String wire;
  final List<String> aliases;

  static const required = [ImportField.name, ImportField.mobile];

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

/// The import's progress, as the server reports it.
class ImportJob {
  const ImportJob({
    required this.id,
    required this.total,
    required this.processed,
    required this.imported,
    required this.duplicates,
    required this.failed,
    required this.done,
  });

  final int id;
  final int total;
  final int processed;
  final int imported;
  final int duplicates;
  final int failed;
  final bool done;

  double get progress => total == 0 ? 1 : processed / total;

  factory ImportJob.fromJson(Map<String, dynamic> json) => ImportJob(
    id: jsonInt(json['Id']) ?? 0,
    total: jsonInt(json['Total']) ?? 0,
    processed: jsonInt(json['Processed']) ?? 0,
    imported: jsonInt(json['Imported']) ?? 0,
    duplicates: jsonInt(json['Duplicates']) ?? 0,
    failed: jsonInt(json['Failed']) ?? 0,
    done: json['Status'] == 'Done',
  );
}

class ImportRequest {
  const ImportRequest({required this.fileName, required this.rows});

  final String fileName;

  /// One map per row, keyed by [ImportField.wire].
  final List<Map<String, String>> rows;

  Map<String, dynamic> toJson() => {'FileName': fileName, 'Rows': rows};
}
