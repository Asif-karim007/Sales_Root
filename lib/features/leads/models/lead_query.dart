import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/leads/models/lead.dart';

/// The quick chips over the list.
enum LeadChip { all, dueToday, stalled, hot }

/// What the list and board show. [mine] narrows to the user's own leads;
/// otherwise [ownerId] picks one owner, or everyone when null.
class LeadFilter {
  const LeadFilter({
    this.search = '',
    this.chip = LeadChip.all,
    this.stageId,
    this.mine = true,
    this.ownerId,
    this.source,
    this.temperature,
  });

  final String search;
  final LeadChip chip;
  final String? stageId;
  final bool mine;
  final String? ownerId;
  final String? source;
  final LeadTemperature? temperature;

  /// How many sheet filters differ from the defaults.
  int get activeCount => [
    stageId != null,
    !mine,
    source != null,
    temperature != null,
  ].where((set) => set).length;

  LeadFilter copyWith({
    String? search,
    LeadChip? chip,
    String? Function()? stageId,
    bool? mine,
    String? Function()? ownerId,
    String? Function()? source,
    LeadTemperature? Function()? temperature,
  }) => LeadFilter(
    search: search ?? this.search,
    chip: chip ?? this.chip,
    stageId: stageId != null ? stageId() : this.stageId,
    mine: mine ?? this.mine,
    ownerId: ownerId != null ? ownerId() : this.ownerId,
    source: source != null ? source() : this.source,
    temperature: temperature != null ? temperature() : this.temperature,
  );

  /// The sheet filters reset, keeping the search and chip.
  LeadFilter cleared() => LeadFilter(search: search, chip: chip);

  LeadQuery query({
    int page = 1,
    int pageSize = 20,
    String? stageId,
    bool withChip = true,
  }) {
    final stage = stageId ?? this.stageId;
    return LeadQuery(
      page: page,
      pageSize: pageSize,
      search: search,
      chip: withChip ? chip : LeadChip.all,
      stageId: stage,
      openOnly: stage == null,
      mine: mine,
      ownerId: mine ? null : ownerId,
      source: source,
      temperature: temperature,
    );
  }
}

/// Paging and filters for `GET leads`. Only values that are set are sent.
class LeadQuery {
  const LeadQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.chip = LeadChip.all,
    this.stageId,
    this.openOnly = true,
    this.mine = false,
    this.ownerId,
    this.source,
    this.temperature,
  });

  final int page;
  final int pageSize;
  final String search;
  final LeadChip chip;
  final String? stageId;
  final bool openOnly;
  final bool mine;
  final String? ownerId;
  final String? source;
  final LeadTemperature? temperature;

  Map<String, dynamic> toQuery() {
    final search = this.search.trim();
    final temperature = chip == LeadChip.hot
        ? LeadTemperature.hot
        : this.temperature;
    return {
      ...pageQuery(page, size: pageSize),
      'q': search.isEmpty ? null : search,
      'scope': mine
          ? 'mine'
          : ownerId == null
          ? 'all'
          : null,
      'ownerId': ownerId,
      'stageId': stageId,
      'status': openOnly ? LeadStatus.open.wire : null,
      'source': source,
      'temperature': temperature?.wire,
      'dueToday': chip == LeadChip.dueToday ? true : null,
      'sleeping': chip == LeadChip.stalled ? true : null,
    }..removeWhere((_, v) => v == null);
  }
}
