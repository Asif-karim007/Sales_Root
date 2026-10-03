import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/data/config_fixtures.dart';
import 'package:salesroot/features/settings/data/config_repository.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

class FakeConfigRepository implements ConfigRepository {
  FakeConfigRepository(this._backend);

  final FakeBackend _backend;

  static const _easyLimit = 4;
  static const _minOpen = 2;

  FakeTable get _pipelines => _backend.store.table(
    '${_backend.graph.workspaceId}/settings/pipelines',
    () => pipelineFixtures(_backend.graph),
    always: true,
  );

  FakeTable get _fields => _backend.store.table(
    '${_backend.graph.workspaceId}/settings/form_fields',
    () => formFieldFixtures(_backend.graph),
    always: true,
  );

  @override
  Future<List<Pipeline>> pipelines() => _backend.run(
    'Pipelines',
    () => [for (final row in _pipelines.rows) Pipeline.fromJson(row)],
    module: AppModule.pipelines,
  );

  @override
  Future<Pipeline> addStage(int pipelineId, StageInput input) =>
      _mutate('Stage add', pipelineId, (stages) {
        final json = _validate(input.toJson(), stages);
        final open = stages.where(_isOpen).length;
        return [
          ...stages.take(open),
          {
            ...json,
            'Id': _nextStageId(),
            'Kind': 'Open',
            'RequiresReason': false,
          },
          ...stages.skip(open),
        ];
      });

  @override
  Future<Pipeline> editStage(int pipelineId, int stageId, StageInput input) =>
      _mutate('Stage edit', pipelineId, (stages) {
        final current = _stage(stages, stageId);
        final json = _validate(input.toJson(), stages, editing: stageId);
        final patch = _isOpen(current)
            ? json
            : {'Name': json['Name'], 'NameBn': json['NameBn']};
        return [
          for (final s in stages) s['Id'] == stageId ? {...s, ...patch} : s,
        ];
      });

  @override
  Future<Pipeline> deleteStage(int pipelineId, int stageId) =>
      _mutate('Stage delete', pipelineId, (stages) {
        if (!_isOpen(_stage(stages, stageId))) {
          throw const ApiFailure(400, 'Won and lost stages can’t be removed');
        }
        if (stages.where(_isOpen).length <= _minOpen) {
          throw const ApiFailure(400, 'A pipeline needs at least 2 stages');
        }
        return [
          for (final s in stages)
            if (s['Id'] != stageId) s,
        ];
      }, right: ModuleRight.delete);

  @override
  Future<Pipeline> reorderStages(int pipelineId, List<int> openStageIds) =>
      _mutate('Stage reorder', pipelineId, (stages) {
        final open = stages.where(_isOpen).toList();
        final ids = {for (final s in open) s['Id']};
        if (ids.length != openStageIds.length ||
            !openStageIds.every(ids.contains)) {
          throw const ApiFailure(409, 'The stages changed. Reload and retry.');
        }
        return [
          for (final id in openStageIds) _stage(open, id),
          ...stages.where((s) => !_isOpen(s)),
        ];
      });

  @override
  Future<List<FormFieldConfig>> formFields(FormKind form) => _backend.run(
    'Form fields',
    () => [
      for (final row in _fields.rows)
        if (row['Form'] == form.wire) FormFieldConfig.fromJson(row),
    ],
    module: AppModule.formFields,
  );

  @override
  Future<FormFieldConfig> saveFormField(int id, FormFieldInput input) =>
      _backend.run(
        'Form field save',
        () {
          final row = _fields.byId(id);
          final json = input.toJson();
          final levels = json['Levels'] as List;
          if (row['IsSystem'] == true) {
            throw const ApiFailure(400, 'Name and mobile are always shown');
          }
          if (json['Required'] == true && levels.length < 3) {
            throw const ApiFailure(
              400,
              'A required field must show at every level',
              fieldErrors: {'Levels': 'Show it at every level first'},
            );
          }
          return FormFieldConfig.fromJson(_fields.update(id, json));
        },
        module: AppModule.formFields,
        right: ModuleRight.edit,
      );

  Future<Pipeline> _mutate(
    String label,
    int pipelineId,
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>> stages)
    change, {
    ModuleRight right = ModuleRight.edit,
  }) => _backend.run(
    label,
    () {
      final row = _pipelines.byId(pipelineId);
      final stages = [
        for (final s in row['Stages'] as List)
          Map<String, dynamic>.of(s as Map<String, dynamic>),
      ];
      final next = change(stages);
      final easy = next.where((s) => _isOpen(s) && s['MinLevel'] == 'Easy');
      if (easy.length > _easyLimit) {
        throw const ApiFailure(
          400,
          'Easy mode shows at most 4 stages',
          fieldErrors: {'MinLevel': 'Easy mode shows at most 4 stages'},
        );
      }
      return Pipeline.fromJson(_pipelines.update(pipelineId, {'Stages': next}));
    },
    module: AppModule.pipelines,
    right: right,
  );

  Map<String, dynamic> _validate(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> stages, {
    int? editing,
  }) {
    fakeRequire(json, ['Name', 'NameBn']);
    final win = json['WinPercent'] as int;
    if (win < 0 || win > 100) {
      throw const ApiFailure(
        400,
        'Win probability is between 0 and 100',
        fieldErrors: {'WinPercent': 'Between 0 and 100'},
      );
    }
    final name = (json['Name'] as String).toLowerCase();
    final taken = stages.any(
      (s) =>
          s['Id'] != editing &&
          (s['Name'] as String? ?? '').toLowerCase() == name,
    );
    if (taken) {
      throw const ApiFailure(
        409,
        'A stage with this name already exists',
        fieldErrors: {'Name': 'Already used in this pipeline'},
      );
    }
    return json;
  }

  int _nextStageId() {
    var max = 0;
    for (final row in _pipelines.rows) {
      for (final s in row['Stages'] as List) {
        final id = (s as Map<String, dynamic>)['Id'] as int;
        if (id > max) max = id;
      }
    }
    return max + 1;
  }

  static bool _isOpen(Map<String, dynamic> stage) => stage['Kind'] == 'Open';

  static Map<String, dynamic> _stage(
    List<Map<String, dynamic>> stages,
    int id,
  ) => stages.firstWhere(
    (s) => s['Id'] == id,
    orElse: () => throw const ApiFailure(404, 'Stage not found'),
  );
}
