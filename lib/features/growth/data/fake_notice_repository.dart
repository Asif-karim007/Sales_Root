import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/data/fake_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/growth/data/campaign_fixtures.dart';
import 'package:salesroot/features/growth/data/notice_fixtures.dart';
import 'package:salesroot/features/growth/data/notice_repository.dart';
import 'package:salesroot/features/growth/models/notice.dart';

class FakeNoticeRepository implements NoticeRepository {
  FakeNoticeRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _notices => _backend.table(growthNoticesTable, noticeFixtures);

  FakeTable get _balance => _backend.table(growthBalanceTable, balanceFixtures);

  ModuleAccess get _grant =>
      ModuleAccess.fromPermission(fakeGrant(_backend.role, AppModule.notice));

  @override
  Future<PageResult<Notice>> list({int page = 1}) =>
      _backend.run('Notices', () {
        final rows = [for (final row in _notices.rows) _shape(row)]
          ..sort(_pinnedThenNewest);
        return PageResult.fromJson(fakePage(rows, page: page), Notice.fromJson);
      }, module: AppModule.notice);

  @override
  Future<Notice> get(int id) => _backend.run(
    'Notice',
    () => Notice.fromJson(_shape(_notices.byId(id))),
    module: AppModule.notice,
  );

  @override
  Future<Notice> markRead(int id) => _backend.run(
    'Notice read',
    () => Notice.fromJson(_shape(_stamp(id, acknowledge: false))),
    module: AppModule.notice,
  );

  @override
  Future<Notice> acknowledge(int id) => _backend.run('Notice acknowledge', () {
    if (_notices.byId(id)['RequiresAck'] != true) {
      throw const ApiFailure(400, 'This notice needs no acknowledgement');
    }
    return Notice.fromJson(_shape(_stamp(id, acknowledge: true)));
  }, module: AppModule.notice);

  @override
  Future<int> remind(int id, List<int> memberIds) =>
      _backend.run('Notice remind', () {
        final row = _notices.byId(id);
        if (!_seesReaders(row)) {
          throw const ApiFailure(403, 'Only the author can send reminders');
        }
        final now = jsonUtc(DateTime.now());
        var reminded = 0;
        final recipients = [
          for (final recipient in _recipients(row))
            if (memberIds.contains(recipient['MemberId']) &&
                recipient['AcknowledgedAt'] == null)
              {...recipient, 'RemindedAt': now}
            else
              recipient,
        ];
        for (final recipient in recipients) {
          if (recipient['RemindedAt'] == now) reminded++;
        }
        if (reminded == 0) {
          throw const ApiFailure(400, 'Everyone picked has already seen it');
        }
        _notices.update(id, {'Recipients': recipients});
        return reminded;
      }, module: AppModule.notice);

  @override
  Future<Notice> create(NoticeInput input) => _backend.run(
    'Notice create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Title', 'Body']);
      final graph = _backend.graph;
      final me = graph.me;
      final audience = noticeAudience(graph, input.audience, me.id);
      if (audience.isEmpty) {
        throw const ApiFailure(400, 'Nobody is in this audience yet');
      }
      if (input.sms) _spendSms(audience.length);
      final now = DateTime.now();
      final pinDays = input.pinDays;
      final row = _notices.insert({
        'Title': input.title.trim(),
        'Body': input.body.trim(),
        'AuthorId': me.id,
        'AuthorName': me.name,
        'AuthorNameBn': me.nameBn,
        'AuthorRole': switch (_backend.role) {
          WorkspaceRole.owner => 'Owner',
          WorkspaceRole.teamLead => 'TeamLead',
          WorkspaceRole.member => 'Admin',
        },
        'PostedAt': jsonUtc(now),
        'Audience': input.audience.wire,
        'RequiresAck': input.requiresAck,
        'Pinned': pinDays != null,
        'PinUntil': pinDays == null
            ? null
            : jsonUtc(now.add(Duration(days: pinDays))),
        'Attachments': body['Attachments'],
        'Recipients': [for (final member in audience) noticeRecipient(member)],
      });
      return Notice.fromJson(_shape(row));
    },
    module: AppModule.notice,
    right: ModuleRight.add,
  );

  @override
  Future<void> delete(int id) => _backend.run(
    'Notice delete',
    () => _notices.delete(id),
    module: AppModule.notice,
    right: ModuleRight.delete,
  );

  @override
  Future<Map<NoticeAudience, int>> audienceCounts() => _backend.run(
    'Notice audiences',
    () => {
      for (final audience in NoticeAudience.values)
        audience: noticeAudience(
          _backend.graph,
          audience,
          _backend.meId,
        ).length,
    },
    module: AppModule.notice,
  );

  List<Map<String, dynamic>> _recipients(Map<String, dynamic> row) => [
    for (final item in row['Recipients'] as List? ?? const [])
      if (item is Map<String, dynamic>) item,
  ];

  bool _seesReaders(Map<String, dynamic> row) =>
      row['AuthorId'] == _backend.meId || _grant.canEdit;

  Map<String, dynamic> _stamp(int id, {required bool acknowledge}) {
    final row = _notices.byId(id);
    final now = jsonUtc(DateTime.now());
    return _notices.update(id, {
      'Recipients': [
        for (final recipient in _recipients(row))
          if (recipient['MemberId'] == _backend.meId)
            {
              ...recipient,
              'ReadAt': recipient['ReadAt'] ?? now,
              if (acknowledge)
                'AcknowledgedAt': recipient['AcknowledgedAt'] ?? now,
            }
          else
            recipient,
      ],
    });
  }

  Map<String, dynamic> _shape(Map<String, dynamic> row) {
    final recipients = _recipients(row);
    final mine = recipients
        .where((r) => r['MemberId'] == _backend.meId)
        .firstOrNull;
    final authored = row['AuthorId'] == _backend.meId;
    final state = mine == null
        ? (authored ? NoticeState.read : NoticeState.unread)
        : mine['AcknowledgedAt'] != null
        ? NoticeState.acknowledged
        : mine['ReadAt'] != null
        ? NoticeState.read
        : NoticeState.unread;
    return {
      ...row,
      'AudienceCount': recipients.length,
      'ReadCount': recipients.where((r) => r['ReadAt'] != null).length,
      'AckCount': recipients.where((r) => r['AcknowledgedAt'] != null).length,
      'MyState': state.wire,
      'Recipients': _seesReaders(row) ? recipients : const [],
      'CanEdit': authored || _grant.canEdit,
      'CanDelete': authored || _grant.canDelete,
    };
  }

  void _spendSms(int credits) {
    final wallet = _balance.rows.isEmpty
        ? _balance.insert(balanceFixtures(_backend.graph).first)
        : _balance.rows.first;
    final have = jsonInt(wallet['SmsCredits']) ?? 0;
    if (credits > have) {
      throw ApiFailure(
        402,
        'Not enough SMS credits: $credits needed, $have left',
        quota: QuotaKind.smsCredits,
      );
    }
    _balance.update(jsonInt(wallet['Id']) ?? 1, {'SmsCredits': have - credits});
  }

  static int _pinnedThenNewest(Map<String, dynamic> a, Map<String, dynamic> b) {
    final pinned = (b['Pinned'] == true ? 1 : 0).compareTo(
      a['Pinned'] == true ? 1 : 0,
    );
    if (pinned != 0) return pinned;
    return '${b['PostedAt']}'.compareTo('${a['PostedAt']}');
  }
}
