import 'package:salesroot/core/utils/json_fields.dart';

enum StageKind { open, won, lost }

class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.name,
    required this.winPercent,
    required this.kind,
    required this.showInEasy,
    required this.universalStep,
    this.requiredFields = const [],
  });

  final String id;
  final LocalizedName name;
  final int winPercent;
  final StageKind kind;
  final bool showInEasy;

  /// The step of the universal sales flow this stage stands for.
  final int universalStep;

  /// Lead fields that must be filled before a lead enters the stage.
  final List<String> requiredFields;

  bool get isOpen => kind == StageKind.open;

  factory PipelineStage.fromJson(Map<String, dynamic> json) => PipelineStage(
    id: jsonId(json['id']) ?? '',
    name: LocalizedName.pair(json),
    winPercent: jsonInt(json['probability']) ?? 0,
    kind: jsonBool(json['isWon'])
        ? StageKind.won
        : jsonBool(json['isLost'])
        ? StageKind.lost
        : StageKind.open,
    showInEasy: jsonBool(json['showInEasy']),
    universalStep: jsonInt(json['universalStep']) ?? 1,
    requiredFields: jsonStrings(json['requiredFields']),
  );
}

class Pipeline {
  const Pipeline({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.stages,
  });

  final String id;
  final String name;
  final bool isDefault;

  /// In board order.
  final List<PipelineStage> stages;

  List<PipelineStage> get openStages => stages.where((s) => s.isOpen).toList();

  /// `GET workspaces/pipelines`: `{pipelines: […], stages: […]}`, the stages
  /// of every pipeline in one list with their `pipelineId` and `sortOrder`.
  static List<Pipeline> listFromJson(Map<String, dynamic> json) {
    final stages = jsonList(json['stages'], (s) => s)
      ..sort(
        (a, b) => (jsonInt(a['sortOrder']) ?? 0).compareTo(
          jsonInt(b['sortOrder']) ?? 0,
        ),
      );
    return [
      for (final p in jsonList(json['pipelines'], (p) => p))
        Pipeline(
          id: jsonId(p['id']) ?? '',
          name: p['name'] as String? ?? '',
          isDefault: jsonBool(p['isDefault']),
          stages: [
            for (final s in stages)
              if (jsonId(s['pipelineId']) == jsonId(p['id']))
                PipelineStage.fromJson(s),
          ],
        ),
    ];
  }

  /// The same pipeline with its open stages in [open]'s order; won and lost
  /// stages keep their places.
  Pipeline withOpenOrder(List<PipelineStage> open) {
    final next = open.iterator;
    return Pipeline(
      id: id,
      name: name,
      isDefault: isDefault,
      stages: [
        for (final stage in stages)
          if (stage.isOpen) (next..moveNext()).current else stage,
      ],
    );
  }
}

/// A new or edited stage: `StageRequest`.
class StageInput {
  const StageInput({
    required this.nameEn,
    required this.nameBn,
    required this.winPercent,
    required this.showInEasy,
    required this.universalStep,
    this.requiredFields = const [],
  });

  final String nameEn;
  final String nameBn;
  final int winPercent;
  final bool showInEasy;
  final int universalStep;
  final List<String> requiredFields;

  Map<String, dynamic> toJson() => {
    'nameEn': nameEn.trim(),
    'nameBn': nameBn.trim(),
    'universalStep': universalStep,
    'showInEasy': showInEasy,
    'probability': winPercent,
    'requiredFields': requiredFields,
  };
}
