import 'package:salesroot/features/settings/models/csv_import.dart';

abstract interface class ImportRepository {
  /// The ones among [phones] (see `normalizePhone`) already saved for a
  /// contact.
  Future<Set<String>> knownPhones(List<String> phones);

  /// Starts an import job and reports its progress until it is done. Rows
  /// whose number is already saved are imported and flagged as duplicates;
  /// rows without a name or mobile fail.
  Stream<ImportJob> importLeads(ImportRequest request);
}
