import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// One pipeline stage, with the win probability a lead takes on there.
class LeadStage {
  const LeadStage({
    required this.id,
    required this.name,
    this.hint = const LocalizedName('', ''),
    this.winProbability = 0,
    this.funnelOrder = 0,
    this.isWon = false,
    this.isLost = false,
  });

  final int id;
  final LocalizedName name;

  /// What the stage means, shown under its name when moving a lead.
  final LocalizedName hint;
  final int winProbability;
  final int funnelOrder;
  final bool isWon;
  final bool isLost;

  bool get isOpen => !isWon && !isLost;

  factory LeadStage.fromJson(Map<String, dynamic> json) => LeadStage(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    hint: LocalizedName(
      json['Hint'] as String? ?? '',
      json['HintBn'] as String? ?? '',
    ),
    winProbability: jsonInt(json['WinProbability']) ?? 0,
    funnelOrder: jsonInt(json['FunnelOrder']) ?? 0,
    isWon: jsonBool(json['IsWon']),
    isLost: jsonBool(json['IsLost']),
  );
}

extension LeadStageList on List<LeadStage> {
  static const int _easyOpenStages = 3;

  LeadStage? byId(int? id) {
    for (final stage in this) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  LeadStage? get won => _first((s) => s.isWon);

  LeadStage? get lost => _first((s) => s.isLost);

  /// The open stages and Won, in funnel order. Easy keeps the first three
  /// open stages only.
  List<LeadStage> visibleFor(ExperienceLevel level) {
    final open = where((s) => s.isOpen).toList()
      ..sort((a, b) => a.funnelOrder.compareTo(b.funnelOrder));
    final won = this.won;
    return [
      ...level == ExperienceLevel.easy ? open.take(_easyOpenStages) : open,
      ?won,
    ];
  }

  /// [visibleFor] plus Lost: the pipeline board's columns.
  List<LeadStage> columnsFor(ExperienceLevel level) => [
    ...visibleFor(level),
    ?lost,
  ];

  /// Where [stageId] sits among [visible]; a stage Easy hides counts as the
  /// last visible stage before it.
  int positionIn(List<LeadStage> visible, int? stageId) {
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
