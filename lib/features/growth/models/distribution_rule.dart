import 'package:salesroot/core/utils/json_fields.dart';

enum AssignMode {
  member('Member'),
  roundRobin('RoundRobin'),
  byLoad('ByLoad'),
  queue('Queue');

  const AssignMode(this.wire);

  final String wire;

  static AssignMode fromWire(String? value) => values.firstWhere(
    (mode) => mode.wire == value,
    orElse: () => AssignMode.queue,
  );
}

/// Where a lead came from, as a rule matches it.
enum RuleSource {
  facebook('Facebook'),
  website('Website'),
  whatsapp('WhatsApp'),
  messenger('Messenger'),
  sms('SMS'),
  call('Phone call');

  const RuleSource(this.wire);

  final String wire;

  static RuleSource fromWire(String? value) => values.firstWhere(
    (source) => source.wire == value,
    orElse: () => RuleSource.website,
  );
}

/// One "if this, then assign" rule. Empty condition lists match anything.
class DistributionRule {
  const DistributionRule({
    required this.id,
    required this.name,
    required this.mode,
    this.position = 0,
    this.enabled = true,
    this.sources = const [],
    this.areas = const [],
    this.forms = const [],
    this.memberIds = const [],
    this.onlyCheckedIn = false,
    this.skipOnLeave = true,
    this.fallbackMemberId,
    this.escalateMinutes,
    this.days = const [],
    this.fromHour,
    this.toHour,
    this.dailyCap,
    this.cursor = 0,
    this.canEdit = true,
    this.canDelete = true,
  });

  final String id;
  final int position;
  final String name;
  final bool enabled;

  /// Source wires, e.g. `Facebook`.
  final List<String> sources;

  /// Area names in English, e.g. `Uttara`.
  final List<String> areas;

  /// Form or campaign names.
  final List<String> forms;
  final AssignMode mode;
  final List<String> memberIds;
  final bool onlyCheckedIn;
  final bool skipOnLeave;
  final String? fallbackMemberId;
  final int? escalateMinutes;

  /// ISO weekdays (1 = Monday) the rule runs on; empty means every day.
  final List<int> days;

  /// The rule runs from [fromHour] up to [toHour]; null means all day.
  final int? fromHour;
  final int? toHour;

  /// Most leads one member gets from this rule in a day.
  final int? dailyCap;

  /// The round-robin position the server keeps.
  final int cursor;
  final bool canEdit;
  final bool canDelete;

  bool get isCatchAll => sources.isEmpty && areas.isEmpty && forms.isEmpty;

  DistributionRule withEnabled(bool enabled) => DistributionRule(
    id: id,
    position: position,
    name: name,
    enabled: enabled,
    sources: sources,
    areas: areas,
    forms: forms,
    mode: mode,
    memberIds: memberIds,
    onlyCheckedIn: onlyCheckedIn,
    skipOnLeave: skipOnLeave,
    fallbackMemberId: fallbackMemberId,
    escalateMinutes: escalateMinutes,
    days: days,
    fromHour: fromHour,
    toHour: toHour,
    dailyCap: dailyCap,
    cursor: cursor,
    canEdit: canEdit,
    canDelete: canDelete,
  );

  bool get hasSchedule =>
      days.isNotEmpty || (fromHour != null && toHour != null);

  factory DistributionRule.fromJson(Map<String, dynamic> json) =>
      DistributionRule(
        id: jsonId(json['Id']) ?? '',
        position: jsonInt(json['Position']) ?? 0,
        name: json['Name'] as String? ?? '',
        enabled: json['Enabled'] != false,
        sources: jsonStrings(json['Sources']),
        areas: jsonStrings(json['Areas']),
        forms: jsonStrings(json['Forms']),
        mode: AssignMode.fromWire(json['Mode'] as String?),
        memberIds: jsonIds(json['MemberIds']),
        onlyCheckedIn: jsonBool(json['OnlyCheckedIn']),
        skipOnLeave: json['SkipOnLeave'] != false,
        fallbackMemberId: jsonId(json['FallbackMemberId']),
        escalateMinutes: jsonInt(json['EscalateMinutes']),
        days: jsonInts(json['Days']),
        fromHour: jsonInt(json['FromHour']),
        toHour: jsonInt(json['ToHour']),
        dailyCap: jsonInt(json['DailyCap']),
        cursor: jsonInt(json['Cursor']) ?? 0,
        canEdit: json['CanEdit'] != false,
        canDelete: json['CanDelete'] != false,
      );
}

class RuleInput {
  const RuleInput({
    required this.name,
    required this.mode,
    required this.enabled,
    required this.sources,
    required this.areas,
    required this.forms,
    required this.memberIds,
    required this.onlyCheckedIn,
    required this.skipOnLeave,
    required this.days,
    this.fallbackMemberId,
    this.escalateMinutes,
    this.fromHour,
    this.toHour,
    this.dailyCap,
  });

  factory RuleInput.of(DistributionRule rule) => RuleInput(
    name: rule.name,
    mode: rule.mode,
    enabled: rule.enabled,
    sources: rule.sources,
    areas: rule.areas,
    forms: rule.forms,
    memberIds: rule.memberIds,
    onlyCheckedIn: rule.onlyCheckedIn,
    skipOnLeave: rule.skipOnLeave,
    days: rule.days,
    fallbackMemberId: rule.fallbackMemberId,
    escalateMinutes: rule.escalateMinutes,
    fromHour: rule.fromHour,
    toHour: rule.toHour,
    dailyCap: rule.dailyCap,
  );

  final String name;
  final AssignMode mode;
  final bool enabled;
  final List<String> sources;
  final List<String> areas;
  final List<String> forms;
  final List<String> memberIds;
  final bool onlyCheckedIn;
  final bool skipOnLeave;
  final List<int> days;
  final String? fallbackMemberId;
  final int? escalateMinutes;
  final int? fromHour;
  final int? toHour;
  final int? dailyCap;

  RuleInput copyWith({
    String? name,
    AssignMode? mode,
    bool? enabled,
    List<String>? sources,
    List<String>? areas,
    List<String>? forms,
    List<String>? memberIds,
    bool? onlyCheckedIn,
    bool? skipOnLeave,
    List<int>? days,
    String? Function()? fallbackMemberId,
    int? Function()? escalateMinutes,
    (int?, int?)? hours,
    int? Function()? dailyCap,
  }) {
    final window = hours ?? (fromHour, toHour);
    return RuleInput(
      name: name ?? this.name,
      mode: mode ?? this.mode,
      enabled: enabled ?? this.enabled,
      sources: sources ?? this.sources,
      areas: areas ?? this.areas,
      forms: forms ?? this.forms,
      memberIds: memberIds ?? this.memberIds,
      onlyCheckedIn: onlyCheckedIn ?? this.onlyCheckedIn,
      skipOnLeave: skipOnLeave ?? this.skipOnLeave,
      days: days ?? this.days,
      fallbackMemberId: fallbackMemberId == null
          ? this.fallbackMemberId
          : fallbackMemberId(),
      escalateMinutes: escalateMinutes == null
          ? this.escalateMinutes
          : escalateMinutes(),
      fromHour: window.$1,
      toHour: window.$2,
      dailyCap: dailyCap == null ? this.dailyCap : dailyCap(),
    );
  }

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'Mode': mode.wire,
    'Enabled': enabled,
    'Sources': sources,
    'Areas': areas,
    'Forms': forms,
    'MemberIds': memberIds,
    'OnlyCheckedIn': onlyCheckedIn,
    'SkipOnLeave': skipOnLeave,
    'Days': days,
    'FallbackMemberId': fallbackMemberId,
    'EscalateMinutes': escalateMinutes,
    'FromHour': fromHour,
    'ToHour': toHour,
    'DailyCap': dailyCap,
  }..removeWhere((_, value) => value == null);
}

class DistributionSettings {
  const DistributionSettings({required this.enabled, required this.rules});

  final bool enabled;
  final List<DistributionRule> rules;

  factory DistributionSettings.fromJson(Map<String, dynamic> json) =>
      DistributionSettings(
        enabled: json['Enabled'] != false,
        rules: jsonList(json['Rules'], DistributionRule.fromJson),
      );
}

/// A team member, with how distribution sees them today when known.
class GrowthMember {
  const GrowthMember({
    required this.id,
    required this.name,
    this.nameBn = '',
    this.onLeave = false,
    this.checkedIn = false,
    this.openLeads,
    this.assignedToday = 0,
  });

  final String id;
  final String name;
  final String nameBn;
  final bool onLeave;
  final bool checkedIn;
  final int? openLeads;
  final int assignedToday;

  String nameOf(bool bangla) => bangla && nameBn.isNotEmpty ? nameBn : name;

  GrowthMember withAssigned() => GrowthMember(
    id: id,
    name: name,
    nameBn: nameBn,
    onLeave: onLeave,
    checkedIn: checkedIn,
    openLeads: (openLeads ?? 0) + 1,
    assignedToday: assignedToday + 1,
  );

  /// A `GET workspaces/members` row; the load fields come only from the
  /// distribution desk.
  factory GrowthMember.fromJson(Map<String, dynamic> json) => GrowthMember(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? json['phone'] as String? ?? '',
    nameBn: json['nameBn'] as String? ?? '',
    onLeave: jsonBool(json['onLeave']),
    checkedIn: jsonBool(json['checkedIn']),
    openLeads: jsonInt(json['openLeads']),
    assignedToday: jsonInt(json['assignedToday']) ?? 0,
  );
}

/// How the last leads would have been shared out by the current rules.
class RuleTestResult {
  const RuleTestResult({
    required this.total,
    required this.byRule,
    required this.queued,
  });

  final int total;
  final List<RuleTestRow> byRule;
  final int queued;

  factory RuleTestResult.fromJson(Map<String, dynamic> json) => RuleTestResult(
    total: jsonInt(json['Total']) ?? 0,
    byRule: jsonList(json['ByRule'], RuleTestRow.fromJson),
    queued: jsonInt(json['Queued']) ?? 0,
  );
}

class RuleTestRow {
  const RuleTestRow({
    required this.ruleId,
    required this.position,
    required this.count,
  });

  final String ruleId;
  final int position;
  final int count;

  factory RuleTestRow.fromJson(Map<String, dynamic> json) => RuleTestRow(
    ruleId: jsonId(json['RuleId']) ?? '',
    position: jsonInt(json['Position']) ?? 0,
    count: jsonInt(json['Count']) ?? 0,
  );
}
