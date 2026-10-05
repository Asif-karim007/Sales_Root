import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/data/import_repository.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';

class ApiImportRepository implements ImportRepository {
  ApiImportRepository(this._api);

  final SettingsApi _api;

  @override
  Future<ImportResult> preview(List<Map<String, String>> rows) =>
      _run('Import check', rows, commit: false);

  @override
  Future<ImportResult> commit(List<Map<String, String>> rows) =>
      _run('Import', rows, commit: true);

  Future<ImportResult> _run(
    String label,
    List<Map<String, String>> rows, {
    required bool commit,
  }) async {
    final json = await apiRequest(
      label,
      () => _api.importCompanies({'rows': rows, 'commit': commit}),
    );
    return ImportResult.fromJson(jsonMap(json), rows: rows.length);
  }
}
