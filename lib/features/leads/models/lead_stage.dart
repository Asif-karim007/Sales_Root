import 'package:collection/collection.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// One pipeline stage, with the win probability a lead takes on there.
/// [requiredFields] must be filled before a lead moves in: `amount`, or the
/// key of a custom lead field.
class LeadStage {
  const LeadStage({
    required this.id,
    required this.name,
    this.pipelineId,
    this.winProbability = 0,
    this.funnelOrder = 0,
    this.showInEasy = true,
    this.isWon = false,
    this.isLost = false,
    this.requiredFields = const [],
  });

  final String id;
  final LocalizedName name;
  final String? pipelineId;
  final int winProbability;
  final int funnelOrder;
  final bool showInEasy;
  final bool isWon;
  final bool isLost;
  final List<String> requiredFields;

  bool get isOpen => !isWon && !isLost;

  factory LeadStage.fromJson(Map<String, dynamic> json) => LeadStage(
    id: jsonId(json['id']) ?? '',
    name: LocalizedName.pair(json),
    pipelineId: jsonId(json['pipelineId']),
    winProbability: jsonInt(json['probability']) ?? 0,
    funnelOrder: jsonInt(json['sortOrder']) ?? 0,
    showInEasy: json['showInEasy'] != false,
    isWon: jsonBool(json['isWon']),
    isLost: jsonBool(json['isLost']),
    requiredFields: jsonStrings(json['requiredFields']),
  );
}

extension LeadStageList on List<LeadStage> {
  LeadStage? byId(String? id) {
    for (final stage in this) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  LeadStage? get won => _first((s) => s.isWon);

  LeadStage? get lost => _first((s) => s.isLost);

  /// Every stage but Lost, in funnel order. Easy keeps the stages the
  /// workspace marks for it.
  List<LeadStage> visibleFor(ExperienceLevel level) {
    final easy = level == ExperienceLevel.easy;
    return [
      for (final stage in sortedBy((s) => s.funnelOrder))
        if (!stage.isLost && (!easy || stage.showInEasy || stage.isWon)) stage,
    ];
  }

  /// [visibleFor] plus Lost: the pipeline board's columns.
  List<LeadStage> columnsFor(ExperienceLevel level) => [
    ...visibleFor(level),
    ?lost,
  ];

  /// Where [stageId] sits among [visible]; a stage Easy hides counts as the
  /// last visible stage before it.
  int positionIn(List<LeadStage> visible, String? stageId) {
    final stage = byId(stageId);
    if (stage == null) return -1;
    var position = -1;
    for (var i = 0; i < visible.length; i++) {
      if (visible[i].funnelOrder <= stage.funnelOrder) position = i;
    }
    return position;
  }

  LeadStage? _first(bool Function(LeadStage) test) {
    for (final stage in this) {
      if (test(stage)) return stage;
    }
    return null;
  }
}
