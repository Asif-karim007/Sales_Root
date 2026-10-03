import 'dart:math';

import 'package:collection/collection.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/data/team_fixtures.dart';
import 'package:salesroot/features/team/data/team_repository.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

class FakeTeamRepository implements TeamRepository {
  FakeTeamRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _members => _backend.table('team/members', memberFixtures);
  FakeTable get _invites => _backend.table('team/invites', inviteFixtures);

  static final _bdMobile = RegExp(r'^(?:\+?88)?(01[3-9]\d{8})$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<PageResult<Member>> members(MemberQuery query) =>
      _backend.run('Team members', () {
        final rows = _members.rows;
        final filtered = switch (query.filter) {
          MemberFilter.all => rows,
          MemberFilter.activeToday => rows.where(_activeToday),
          MemberFilter.pending => const <Map<String, dynamic>>[],
          MemberFilter.teamLeads => rows.where(_isLead),
        };
        final page = fakePage(
          [for (final row in _sorted(filtered)) _present(row)],
          page: query.page,
          extra: {
            'Counts': {
              MemberFilter.all.wire: rows.length,
              MemberFilter.activeToday.wire: rows.where(_activeToday).length,
              MemberFilter.pending.wire: _invites.rows.length,
              MemberFilter.teamLeads.wire: rows.where(_isLead).length,
            },
          },
        );
        return PageResult.fromJson(page, Member.fromJson);
      }, module: AppModule.team);

  @override
  Future<List<Member>> directory() => _backend.run(
    'Team directory',
    () => [
      for (final row in _sorted(_members.rows)) Member.fromJson(_present(row)),
    ],
    module: AppModule.team,
  );

  @override
  Future<Member> member(int id) => _backend.run(
    'Team member',
    () => Member.fromJson(_present(_members.byId(id), withStats: true)),
    module: AppModule.team,
  );

  @override
  Future<Member> updateMember(int id, MemberUpdate update) => _backend.run(
    'Team member update',
    () {
      final row = _members.byId(id);
      final body = update.toJson();
      final isOwner = row['Role'] == WorkspaceRole.owner.wire;
      if (isOwner && (body.containsKey('Role') || body['IsActive'] == false)) {
        throw const ApiFailure(400, "The owner's role can't be changed");
      }
      if (body['Role'] == WorkspaceRole.owner.wire) {
        throw const ApiFailure(400, 'There can be only one owner');
      }
      final managerId = jsonInt(body['ManagerId']);
      if (managerId != null) _requireManager(managerId, forId: id);
      final isActive = body['IsActive'];
      _members.update(id, {
        ...body,
        if (isActive == false) 'StatusToday': 'Deactivated',
        if (isActive == true) 'StatusToday': 'NotStarted',
      });
      return Member.fromJson(_present(_members.byId(id), withStats: true));
    },
    module: AppModule.team,
    right: ModuleRight.edit,
  );

  @override
  Future<void> removeMember(int id, RemovalInput input) => _backend.run(
    'Team member remove',
    () {
      final body = input.toJson();
      fakeRequire(body, ['ReassignToId']);
      final row = _members.byId(id);
      if (row['Role'] == WorkspaceRole.owner.wire) {
        throw const ApiFailure(400, "The owner can't be removed");
      }
      final target = _members.byIdOrNull(jsonInt(body['ReassignToId']) ?? 0);
      if (target == null || target['Id'] == id || target['IsActive'] == false) {
        throw const ApiFailure(
          400,
          'Choose an active member to take over',
          fieldErrors: {'ReassignToId': 'Choose an active member'},
        );
      }
      final newManager = row['ManagerId'] ?? ownerIdOf(_backend.graph);
      for (final report in _members.rows.where((r) => r['ManagerId'] == id)) {
        _members.update(report['Id'] as int, {'ManagerId': newManager});
      }
      _members.delete(id);
    },
    module: AppModule.team,
    right: ModuleRight.delete,
  );

  @override
  Future<List<Invite>> invites() => _backend.run(
    'Team invites',
    () => [for (final row in _invites.rows) _inviteOf(row)],
    module: AppModule.team,
    right: ModuleRight.add,
  );

  @override
  Future<Invite> invite(int id) => _backend.run(
    'Team invite',
    () => _inviteOf(_invites.byId(id)),
    module: AppModule.team,
    right: ModuleRight.add,
  );

  @override
  Future<Invite> sendInvite(InviteInput input) => _backend.run(
    'Team invite send',
    () {
      final body = input.toJson();
      final byPhone = input.channel == InviteChannel.phone;
      fakeRequire(body, [byPhone ? 'Phone' : 'Email']);
      final address = byPhone
          ? _normalisedPhone(body['Phone'] as String)
          : _checkedEmail(body['Email'] as String);
      if (_taken(address)) {
        throw ApiFailure(
          409,
          'Already in the team or invited',
          fieldErrors: {byPhone ? 'Phone' : 'Email': 'Already invited'},
        );
      }
      final managerId = jsonInt(body['ManagerId']);
      if (managerId != null) _requireManager(managerId);
      final id = _invites.nextId();
      final code = _code(id);
      final row = _invites.insert({
        ...body,
        'Id': id,
        if (byPhone) 'Phone': address else 'Email': address,
        'Code': code,
        'Link': inviteLink(code),
        'SentAt': jsonUtc(DateTime.now()),
      });
      return _inviteOf(row);
    },
    module: AppModule.team,
    right: ModuleRight.add,
    quota: QuotaKind.users,
  );

  @override
  Future<Invite> resendInvite(int id) => _backend.run(
    'Team invite resend',
    () => _inviteOf(_invites.update(id, {'SentAt': jsonUtc(DateTime.now())})),
    module: AppModule.team,
    right: ModuleRight.add,
  );

  @override
  Future<void> revokeInvite(int id) => _backend.run(
    'Team invite revoke',
    () => _invites.delete(id),
    module: AppModule.team,
    right: ModuleRight.add,
  );

  @override
  Future<List<SeatPack>> seatPacks() => _backend.run('Seat packs', () {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month + 1, 0).day;
    final left = days - now.day + 1;
    return [
      for (final (seats, price) in seatPackPrices)
        SeatPack.fromJson({
          'Seats': seats,
          'PricePerMonth': price,
          'ProratedToday': (price * left / days).round(),
        }),
    ];
  });

  bool _activeToday(Map<String, dynamic> row) => row['StatusToday'] == 'Active';

  bool _isLead(Map<String, dynamic> row) =>
      row['Role'] == WorkspaceRole.teamLead.wire;

  List<Map<String, dynamic>> _sorted(Iterable<Map<String, dynamic>> rows) {
    int rank(Map<String, dynamic> row) => row['IsActive'] == false
        ? 3
        : WorkspaceRole.fromWire(row['Role'] as String?).index;
    return rows.sorted((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : (a['Id'] as int).compareTo(b['Id'] as int);
    });
  }

  /// What the server adds on read: manager name, report count and the
  /// caller's rights on the row.
  Map<String, dynamic> _present(
    Map<String, dynamic> row, {
    bool withStats = false,
  }) {
    final rows = _members.rows;
    final id = row['Id'] as int;
    final manager = rows.firstWhereOrNull((r) => r['Id'] == row['ManagerId']);
    final isOwner = row['Role'] == WorkspaceRole.owner.wire;
    final manages = switch (_backend.role) {
      WorkspaceRole.owner => true,
      WorkspaceRole.teamLead => row['ManagerId'] == _backend.meId,
      WorkspaceRole.member => false,
    };
    return {
      ...row,
      'ManagerName': manager?['Name'],
      'ManagerNameBn': manager?['NameBn'],
      'ReportCount': rows
          .where((r) => r['ManagerId'] == id && r['IsActive'] != false)
          .length,
      'CanEdit': manages && !isOwner,
      'CanDelete': manages && !isOwner && id != _backend.meId,
      'IsMe': id == _backend.meId,
      if (withStats) 'Stats': _stats(id),
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _stats(int id) {
    final graph = _backend.graph;
    final random = graph.random('member-stats-$id');
    final leads = graph.leadsOf(id);
    final open = leads.where((l) => l.isOpen).toList();
    final now = graph.anchor;
    final workingDays = List.generate(
      now.day,
      (i) => DateTime(now.year, now.month, i + 1),
    ).where((day) => day.weekday != DateTime.friday).length;
    final hasWork = leads.isNotEmpty;
    return {
      'LeadsThisMonth': leads.where((l) => l.createdDaysAgo < 30).length,
      'WonValue': leads
          .where((l) => l.stageId == 5)
          .fold<int>(0, (sum, l) => sum + l.value),
      'AttendanceDays': max(0, workingDays - random.nextInt(3)),
      'WorkingDays': workingDays,
      'OpenLeads': open.length,
      'OpenLeadValue': open.fold<int>(0, (sum, l) => sum + l.value),
      'OpenTasks': hasWork ? 3 + random.nextInt(8) : 0,
      'OverdueTasks': hasWork ? random.nextInt(3) : 0,
      'TodayVisits': hasWork ? random.nextInt(4) : 0,
    };
  }

  Invite _inviteOf(Map<String, dynamic> row) {
    final manager = _members.byIdOrNull(jsonInt(row['ManagerId']) ?? 0);
    final sentAt = jsonDate(row['SentAt']);
    final sentDaysAgo = sentAt == null
        ? 0
        : DateTime.now().difference(sentAt).inDays;
    return Invite.fromJson(
      {
        ...row,
        'ManagerName': manager?['Name'],
        'ManagerNameBn': manager?['NameBn'],
        'SentDaysAgo': sentDaysAgo,
        'ExpiresInDays': max(0, 7 - sentDaysAgo),
      }..removeWhere((_, value) => value == null),
    );
  }

  void _requireManager(int managerId, {int? forId}) {
    final manager = _members.byIdOrNull(managerId);
    if (manager == null || managerId == forId || manager['IsActive'] == false) {
      throw const ApiFailure(
        400,
        'Choose who they report to',
        fieldErrors: {'ManagerId': 'Choose an active member'},
      );
    }
  }

  String _normalisedPhone(String phone) {
    final match = _bdMobile.firstMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
    final local = match?.group(1);
    if (local == null) {
      throw const ApiFailure(
        400,
        'Enter a valid mobile number',
        fieldErrors: {'Phone': 'Enter a valid mobile number'},
      );
    }
    return '+88$local';
  }

  String _checkedEmail(String email) {
    final address = email.trim().toLowerCase();
    if (_email.hasMatch(address)) return address;
    throw const ApiFailure(
      400,
      'Enter a valid email address',
      fieldErrors: {'Email': 'Enter a valid email address'},
    );
  }

  bool _taken(String address) =>
      _members.rows.any(
        (r) =>
            jsonStrings(r['PhoneNumbers']).contains(address) ||
            jsonStrings(r['Emails']).contains(address),
      ) ||
      _invites.rows.any((r) => r['Phone'] == address || r['Email'] == address);

  String _code(int id) {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final random = Random(Object.hash(id, DateTime.now().microsecond));
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
