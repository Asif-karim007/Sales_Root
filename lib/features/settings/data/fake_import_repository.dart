import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/data/csv_parser.dart';
import 'package:salesroot/features/settings/data/import_repository.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';

class FakeImportRepository implements ImportRepository {
  FakeImportRepository(this._backend);

  final FakeBackend _backend;

  static const _batch = 25;

  FakeTable get _jobs => _backend.table('settings/imports', (_) => const []);

  Set<String> get _savedPhones => {
    for (final contact in _backend.graph.contacts)
      normalizePhone(contact.phone),
  };

  @override
  Future<Set<String>> knownPhones(List<String> phones) => _backend.run(
    'Import duplicates',
    () => phones.toSet().intersection(_savedPhones),
    module: AppModule.dataImport,
    right: ModuleRight.add,
  );

  @override
  Stream<ImportJob> importLeads(ImportRequest request) async* {
    final started = await _backend.run(
      'Import start',
      () {
        if (request.rows.isEmpty) {
          throw const ApiFailure(400, 'The file has no rows to import');
        }
        return _jobs.insert({
          'Id': _jobs.nextId(),
          'FileName': request.fileName,
          'Total': request.rows.length,
          'Processed': 0,
          'Imported': 0,
          'Duplicates': 0,
          'Failed': 0,
          'Status': 'Running',
          'StartedAt': AppDateUtils.toApiUtc(DateTime.now()),
        });
      },
      module: AppModule.dataImport,
      right: ModuleRight.add,
      quota: QuotaKind.records,
    );
    final id = started['Id'] as int;
    yield ImportJob.fromJson(started);

    final saved = _savedPhones;
    final seen = <String>{};
    final mobile = ImportField.mobile.wire;
    final name = ImportField.name.wire;
    var imported = 0;
    var duplicates = 0;
    var failed = 0;
    for (var start = 0; start < request.rows.length; start += _batch) {
      final batch = request.rows.skip(start).take(_batch);
      final row = await _backend.network('Import progress', () {
        for (final lead in batch) {
          final phone = normalizePhone(lead[mobile] ?? '');
          if ((lead[name] ?? '').trim().isEmpty || phone.isEmpty) {
            failed++;
            continue;
          }
          imported++;
          if (saved.contains(phone) || !seen.add(phone)) duplicates++;
        }
        final processed = start + batch.length;
        return _jobs.update(id, {
          'Processed': processed,
          'Imported': imported,
          'Duplicates': duplicates,
          'Failed': failed,
          if (processed >= request.rows.length) 'Status': 'Done',
        });
      });
      yield ImportJob.fromJson(row);
    }
  }
}
