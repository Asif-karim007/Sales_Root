import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum StageKind {
  open('Open'),
  won('Won'),
  lost('Lost');

  const StageKind(this.wire);

  final String wire;

  static StageKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => StageKind.open);
}

class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.name,
    required this.winPercent,
    required this.kind,
    required this.minLevel,
    this.requiresQuotation = false,
    this.requiresReason = false,
  });

  final int id;
  final LocalizedName name;
  final int winPercent;
  final StageKind kind;

  /// The lowest experience level that shows this stage.
  final ExperienceLevel minLevel;
  final bool requiresQuotation;
  final bool requiresReason;

  bool get isOpen => kind == StageKind.open;

  factory PipelineStage.fromJson(Map<String, dynamic> json) => PipelineStage(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    winPercent: jsonInt(json['WinPercent']) ?? 0,
    kind: StageKind.fromWire(json['Kind'] as String?),
    minLevel:
        ExperienceLevel.fromWire(json['MinLevel'] as String?) ??
        ExperienceLevel.easy,
    requiresQuotation: jsonBool(json['RequiresQuotation']),
    requiresReason: jsonBool(json['RequiresReason']),
  );
}

class Pipeline {
  const Pipeline({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.stages,
  });

  final int id;
  final LocalizedName name;
  final bool isDefault;
  final List<PipelineStage> stages;

  List<PipelineStage> get openStages => stages.where((s) => s.isOpen).toList();

  factory Pipeline.fromJson(Map<String, dynamic> json) => Pipeline(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    isDefault: jsonBool(json['IsDefault']),
    stages: jsonList(json['Stages'], PipelineStage.fromJson),
  );
}

/// A new or edited stage.
class StageInput {
  const StageInput({
    required this.name,
    required this.nameBn,
    required this.winPercent,
    required this.minLevel,
    this.requiresQuotation = false,
  });

  final String name;
  final String nameBn;
  final int winPercent;
  final ExperienceLevel minLevel;
  final bool requiresQuotation;

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'NameBn': nameBn.trim(),
    'WinPercent': winPercent,
    'MinLevel': minLevel.wire,
    'RequiresQuotation': requiresQuotation,
  };
}
