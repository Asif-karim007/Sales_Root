import 'package:collection/collection.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/data/team_api.dart';
import 'package:salesroot/features/team/data/team_repository.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

class ApiTeamRepository implements TeamRepository {
  ApiTeamRepository(this._api, {this.me});

  final TeamApi _api;

  /// The signed-in user's membership id.
  final String? me;

  static const countsKey = 'counts';

  @override
  Future<PageResult<Member>> members(MemberQuery query) async {
    final roster = await _roster();
    final shown = roster.members.where(query.filter.includes).toList();
    return PageResult(
      items: shown,
      page: 1,
      totalCount: shown.length,
      totalPages: 1,
      raw: {
        countsKey: {
          for (final filter in MemberFilter.values)
            filter.wire: filter == MemberFilter.pending
                ? roster.invites.length
                : roster.members.where(filter.includes).length,
        },
      },
    );
  }

  @override
  Future<List<Member>> directory() async => (await _roster()).members;

  @override
  Future<Member> member(String id) async {
    final member = _find((await _roster()).members, id);
    final targets = await _optional('Team targets', _api.targets);
    final row = jsonList(
      jsonMap(targets)['people'],
      (row) => row,
    ).firstWhereOrNull((row) => jsonId(row['membershipId']) == id);
    if (row == null) return member;
    final [openLeads, overdueTasks] = await Future.wait([
      _total(
        'Member open leads',
        () => _api.leads({'ownerId': id, 'status': 'open', 'limit': 1}),
      ),
      _total(
        'Member overdue tasks',
        () => _api.tasks({'assignee': id, 'view': 'overdue', 'limit': 1}),
      ),
    ]);
    return member.copyWith(
      stats: MemberStats.fromJson(
        row,
        openLeads: openLeads,
        overdueTasks: overdueTasks,
      ),
    );
  }

  @override
  Future<Member> updateMember(String id, MemberUpdate update) async {
    await apiRequest(
      'Team member update',
      () => _api.updateMember(id, update.toJson()),
    );
    return _find((await _roster()).members, id);
  }

  @override
  Future<void> removeMember(String id, {required String successorId}) =>
      apiRequest(
        'Team member remove',
        () => _api.updateMember(
          id,
          MemberUpdate(
            status: MembershipStatus.removed,
            successorId: successorId,
          ).toJson(),
        ),
      );

  @override
  Future<List<Invite>> invites() async => (await _roster()).invites;

  @override
  Future<Invite> invite(String id) async {
    final invite = (await _roster()).invites.firstWhereOrNull(
      (i) => i.id == id,
    );
    if (invite == null) throw const ApiFailure(404, 'Invitation not found');
    return invite;
  }

  @override
  Future<Invite> sendInvite(InviteInput input) async {
    final sent = await apiRequest(
      'Team invite send',
      () => _api.invite(input.toJson()),
    );
    return Invite.fromJson({...input.toJson(), ...jsonMap(sent)});
  }

  @override
  Future<void> revokeInvite(String id) => apiRequest(
    'Team invite revoke',
    () => _api.updateMember(
      id,
      const MemberUpdate(status: MembershipStatus.removed).toJson(),
    ),
  );

  @override
  Future<List<SeatPack>> seatPacks(String planKey) async {
    final catalogue = await apiRequest('Plan catalogue', _api.catalogue);
    return SeatPack.fromCatalogue(jsonMap(catalogue), planKey);
  }

  /// Everyone in the workspace, with manager names, report counts and
  /// today's attendance filled in.
  Future<_Roster> _roster() async {
    final [rows, attendance] = await Future.wait([
      apiRequest('Team members', _api.members),
      _optional('Team attendance', _api.attendance),
    ]);
    final all = jsonList(rows, (row) => row);
    final joined = [
      for (final row in all)
        if (row['status'] != MembershipStatus.invited &&
            row['status'] != MembershipStatus.removed)
          Member.fromJson(row),
    ];
    final today = {
      for (final row in jsonList(attendance, (row) => row))
        ?jsonId(row['membershipId']): _statusOf(row),
    };
    final names = {for (final m in joined) m.id: m.name};
    final members = [
      for (final m in joined)
        m.copyWith(
          managerName: names[m.managerId],
          reportCount: joined
              .where((r) => r.managerId == m.id && r.isActive)
              .length,
          status: m.isActive ? today[m.id] : null,
          isMe: m.id == me,
        ),
    ]..sort(_byRank);
    final invites = [
      for (final row in all)
        if (row['status'] == MembershipStatus.invited)
          Invite.fromJson(row).withManager(names[jsonId(row['reportsTo'])]),
    ];
    return _Roster(members, invites);
  }

  static MemberStatus _statusOf(Map<String, dynamic> row) =>
      switch (row['status']) {
        'leave' || 'on_leave' => MemberStatus.onLeave,
        _ when row['checkInAt'] != null => MemberStatus.active,
        _ => MemberStatus.notStarted,
      };

  static int _byRank(Member a, Member b) {
    int rank(Member m) => m.isActive ? m.role.index : MemberRole.values.length;
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.name.en.compareTo(b.name.en);
  }

  static Member _find(List<Member> members, String id) {
    final member = members.firstWhereOrNull((m) => m.id == id);
    if (member == null) throw const ApiFailure(404, 'Member not found');
    return member;
  }

  /// A read the screen can do without: null when the caller may not see it.
  Future<dynamic> _optional(
    String label,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await apiRequest(label, request);
    } on ApiFailure catch (failure) {
      if (failure.isForbidden || failure.isNotFound) return null;
      rethrow;
    }
  }

  Future<int> _total(String label, Future<dynamic> Function() request) async =>
      jsonInt(jsonMap(await _optional(label, request))['total']) ?? 0;
}

class _Roster {
  const _Roster(this.members, this.invites);

  final List<Member> members;
  final List<Invite> invites;
}
