import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/leads/models/lead.dart';

/// The quick chips over the list; their counts come in the `ChipCounts` facet.
enum LeadChip {
  all('All'),
  dueToday('DueToday'),
  overdue('Overdue'),
  stalled('Stalled'),
  hot('Hot');

  const LeadChip(this.wire);

  final String wire;

  static LeadChip fromWire(String? value) => values.firstWhere(
    (chip) => chip.wire == value,
    orElse: () => LeadChip.all,
  );
}

enum LeadCreatedWithin {
  today(0),
  week(7),
  month(30),
  quarter(90);

  const LeadCreatedWithin(this.days);

  final int days;

  DateTime since(DateTime now) =>
      AppDateUtils.dateOnly(now).subtract(Duration(days: days));
}

/// What the list and board show. [mine] narrows to the user's own leads;
/// otherwise [ownerId] picks one owner, or everyone when null.
class LeadFilter {
  const LeadFilter({
    this.search = '',
    this.chip = LeadChip.all,
    this.stageIds = const {},
    this.mine = true,
    this.ownerId,
    this.sourceIds = const {},
    this.tagIds = const {},
    this.temperatures = const {},
    this.minValue,
    this.maxValue,
    this.createdWithin,
  });

  final String search;
  final LeadChip chip;
  final Set<int> stageIds;
  final bool mine;
  final int? ownerId;
  final Set<int> sourceIds;
  final Set<int> tagIds;
  final Set<LeadTemperature> temperatures;
  final double? minValue;
  final double? maxValue;
  final LeadCreatedWithin? createdWithin;

  /// How many sheet filters differ from the defaults.
  int get activeCount => [
    stageIds.isNotEmpty,
    !mine,
    sourceIds.isNotEmpty,
    tagIds.isNotEmpty,
    temperatures.isNotEmpty,
    minValue != null || maxValue != null,
    createdWithin != null,
  ].where((set) => set).length;

  LeadFilter copyWith({
    String? search,
    LeadChip? chip,
    Set<int>? stageIds,
    bool? mine,
    int? Function()? ownerId,
    Set<int>? sourceIds,
    Set<int>? tagIds,
    Set<LeadTemperature>? temperatures,
    double? Function()? minValue,
    double? Function()? maxValue,
    LeadCreatedWithin? Function()? createdWithin,
  }) => LeadFilter(
    search: search ?? this.search,
    chip: chip ?? this.chip,
    stageIds: stageIds ?? this.stageIds,
    mine: mine ?? this.mine,
    ownerId: ownerId != null ? ownerId() : this.ownerId,
    sourceIds: sourceIds ?? this.sourceIds,
    tagIds: tagIds ?? this.tagIds,
    temperatures: temperatures ?? this.temperatures,
    minValue: minValue != null ? minValue() : this.minValue,
    maxValue: maxValue != null ? maxValue() : this.maxValue,
    createdWithin: createdWithin != null ? createdWithin() : this.createdWithin,
  );

  /// The sheet filters reset, keeping the search and chip.
  LeadFilter cleared() => LeadFilter(search: search, chip: chip);

  LeadQuery query({
    required DateTime now,
    int page = 1,
    int pageSize = 20,
    Set<int>? stageIds,
    bool withChip = true,
  }) {
    final stages = stageIds ?? this.stageIds;
    return LeadQuery(
      page: page,
      pageSize: pageSize,
      search: search,
      chip: withChip ? chip : LeadChip.all,
      stageIds: stages,
      openOnly: stages.isEmpty,
      mine: mine,
      ownerId: mine ? null : ownerId,
      sourceIds: sourceIds,
      tagIds: tagIds,
      temperatures: temperatures,
      minValue: minValue,
      maxValue: maxValue,
      createdFrom: createdWithin?.since(now),
    );
  }
}

/// Paging and filters for `GET /leads`. Only values that are set are sent.
class LeadQuery {
  const LeadQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.chip = LeadChip.all,
    this.stageIds = const {},
    this.openOnly = true,
    this.mine = false,
    this.ownerId,
    this.sourceIds = const {},
    this.tagIds = const {},
    this.temperatures = const {},
    this.minValue,
    this.maxValue,
    this.createdFrom,
  });

  final int page;
  final int pageSize;
  final String search;
  final LeadChip chip;
  final Set<int> stageIds;
  final bool openOnly;
  final bool mine;
  final int? ownerId;
  final Set<int> sourceIds;
  final Set<int> tagIds;
  final Set<LeadTemperature> temperatures;
  final double? minValue;
  final double? maxValue;
  final DateTime? createdFrom;

  Map<String, dynamic> toQuery() {
    final createdFrom = this.createdFrom;
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is Iterable && value.isEmpty) return;
      query[key] = value is Iterable ? value.join(',') : value;
    }

    put('search', search.trim());
    put('chip', chip == LeadChip.all ? null : chip.wire);
    put('stageIds', stageIds);
    put('openOnly', openOnly ? true : null);
    put('mine', mine ? true : null);
    put('assignedToEmployeeId', ownerId);
    put('sourceIds', sourceIds);
    put('tagIds', tagIds);
    put('temperatures', [for (final t in temperatures) t.wire]);
    put('minValue', minValue);
    put('maxValue', maxValue);
    put(
      'createdFrom',
      createdFrom == null ? null : AppDateUtils.toApiDateOnly(createdFrom),
    );
    return query;
  }
}

/// The facets every list page carries.
extension LeadFacets on Paged<Lead> {
  static const facetKeys = ['ChipCounts', 'StageCounts', 'Summary'];

  int chipCount(LeadChip chip) => facets['ChipCounts']?[chip.wire] ?? 0;

  int stageCount(int stageId) => facets['StageCounts']?['$stageId'] ?? 0;

  int get openCount => facets['Summary']?['Open'] ?? 0;

  int get closingThisWeek => facets['Summary']?['ClosingThisWeek'] ?? 0;
}
