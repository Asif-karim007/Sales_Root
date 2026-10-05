import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/data/config_repository.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

class ApiConfigRepository implements ConfigRepository {
  ApiConfigRepository(this._api);

  final SettingsApi _api;

  @override
  Future<List<Pipeline>> pipelines() async {
    final json = await apiRequest('Pipelines', () => _api.pipelines());
    return Pipeline.listFromJson(jsonMap(json));
  }

  @override
  Future<void> addStage(String pipelineId, StageInput input) =>
      apiRequest('Stage add', () => _api.addStage(pipelineId, input.toJson()));

  @override
  Future<void> editStage(String stageId, StageInput input) =>
      apiRequest('Stage edit', () => _api.editStage(stageId, input.toJson()));

  @override
  Future<void> reorderStages(List<String> stageIds) =>
      apiRequest('Stage reorder', () => _api.reorderStages(stageIds));

  @override
  Future<List<FormFieldConfig>> formFields(FormKind form) async {
    final json = await apiRequest('Form fields', () => _api.pack());
    return jsonList(jsonMap(json)[form.packKey], FormFieldConfig.fromJson);
  }
}
