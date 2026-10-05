import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

/// Workspace setup the owner manages: pipelines, stages and form fields.
abstract interface class ConfigRepository {
  Future<List<Pipeline>> pipelines();

  Future<void> addStage(String pipelineId, StageInput input);

  Future<void> editStage(String stageId, StageInput input);

  /// Sets the board order of [stageIds].
  Future<void> reorderStages(List<String> stageIds);

  Future<List<FormFieldConfig>> formFields(FormKind form);
}
