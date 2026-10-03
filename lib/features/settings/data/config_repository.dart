import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

/// Workspace setup the owner manages: pipelines, stages and form fields.
abstract interface class ConfigRepository {
  Future<List<Pipeline>> pipelines();

  Future<Pipeline> addStage(int pipelineId, StageInput input);

  Future<Pipeline> editStage(int pipelineId, int stageId, StageInput input);

  Future<Pipeline> deleteStage(int pipelineId, int stageId);

  /// Sets the order of the open stages; won and lost always come last.
  Future<Pipeline> reorderStages(int pipelineId, List<int> openStageIds);

  Future<List<FormFieldConfig>> formFields(FormKind form);

  Future<FormFieldConfig> saveFormField(int id, FormFieldInput input);
}
