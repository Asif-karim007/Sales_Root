import 'package:salesroot/features/settings/models/csv_import.dart';

/// Imports customers from a sheet: one map per row, keyed by
/// [ImportField.wire].
abstract interface class ImportRepository {
  /// Checks [rows] without saving anything.
  Future<ImportResult> preview(List<Map<String, String>> rows);

  Future<ImportResult> commit(List<Map<String, String>> rows);
}
