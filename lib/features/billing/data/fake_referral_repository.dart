import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/data/fake_referral_ledger.dart';
import 'package:salesroot/features/billing/data/referral_repository.dart';
import 'package:salesroot/features/billing/models/referral.dart';

class FakeReferralRepository implements ReferralRepository {
  FakeReferralRepository(this._backend)
    : _ledger = FakeReferralLedger(_backend);

  final FakeBackend _backend;
  final FakeReferralLedger _ledger;

  static const int _leaderboardDays = 30;

  @override
  Future<ReferralOverview> overview() => _backend.run(
    'Referral overview',
    () => ReferralOverview.fromJson(_ledger.overviewJson()),
    module: AppModule.referral,
  );

  @override
  Future<PageResult<Referral>> list(ReferralQuery query) =>
      _backend.run('Referral list', () {
        final all = _ledger.referrals.rows;
        final status = query.status;
        final rows = [
          for (final row in all)
            if (status == null || row['Status'] == status.wire)
              _ledger.referralJson(row),
        ];
        final counts = <String, int>{};
        for (final row in all) {
          final wire = row['Status'] as String? ?? '';
          counts[wire] = (counts[wire] ?? 0) + 1;
        }
        return PageResult.fromJson(
          fakePage(rows, page: query.page, extra: {'StatusCounts': counts}),
          Referral.fromJson,
        );
      }, module: AppModule.referral);

  @override
  Future<PageResult<WalletEntry>> wallet(int page) => _backend.run(
    'Referral wallet',
    () => PageResult.fromJson(
      fakePage([
        for (final row in _ledger.wallet.rows) _ledger.entryJson(row),
      ], page: page),
      WalletEntry.fromJson,
    ),
    module: AppModule.referral,
  );

  @override
  Future<List<LeaderboardEntry>> leaderboard() => _backend.run(
    'Referral leaderboard',
    () {
      final graph = _backend.graph;
      final since = graph.anchor.subtract(
        const Duration(days: _leaderboardDays),
      );
      final mine = _ledger.referrals.rows
          .where((row) => jsonDate(row['BoughtAt'])?.isAfter(since) ?? false)
          .length;
      final random = graph.random('referral-leaderboard');
      final rows = [
        for (final member in graph.members)
          {
            'MemberId': member.id,
            'Name': member.name,
            'NameBn': member.nameBn,
            'Paid': member.id == _backend.meId ? mine : random.nextInt(3),
            'IsMe': member.id == _backend.meId,
          },
      ]..sort((a, b) => (b['Paid'] as int).compareTo(a['Paid'] as int));
      return [for (final row in rows.take(10)) LeaderboardEntry.fromJson(row)];
    },
    module: AppModule.referral,
  );

  @override
  Future<InviteCheck> check(String contact) => _backend.run(
    'Referral check',
    () => InviteCheck.fromJson(_ledger.checkJson(contact)),
    module: AppModule.referral,
    right: ModuleRight.add,
  );

  @override
  Future<Referral> invite(String contact, {required bool sendSms}) =>
      _backend.run(
        'Referral invite',
        () {
          fakeRequire({'Contact': contact}, ['Contact']);
          final check = InviteCheck.fromJson(_ledger.checkJson(contact));
          switch (check.eligibility) {
            case InviteEligibility.invalid:
              throw const ApiFailure(
                400,
                'Enter a valid mobile number or email.',
                fieldErrors: {'Contact': 'Invalid'},
              );
            case InviteEligibility.alreadyUser ||
                InviteEligibility.referredByOther ||
                InviteEligibility.alreadyInvited:
              throw const ApiFailure(409, 'This contact cannot be invited.');
            case InviteEligibility.eligible:
              break;
          }
          final normalized = FakeReferralLedger.normalize(contact) ?? contact;
          final known = _backend.graph.contacts
              .where(
                (c) =>
                    FakeReferralLedger.normalize(c.phone) == normalized ||
                    c.email?.toLowerCase() == normalized,
              )
              .firstOrNull;
          final row = _ledger.referrals.insert({
            'Name': known?.name ?? normalized,
            'NameBn': '',
            'Phone': normalized,
            'Status': ReferralStatus.pending.wire,
            'Channel': sendSms ? 'Sms' : 'Recorded',
            'InvitedAt': AppDateUtils.toApiUtc(_backend.graph.anchor),
          });
          return Referral.fromJson(_ledger.referralJson(row));
        },
        module: AppModule.referral,
        right: ModuleRight.add,
      );

  @override
  Future<List<InviteContact>> contacts(String term, int page) => _backend.run(
    'Referral contacts',
    () {
      final graph = _backend.graph;
      final rows =
          [
            for (final contact in graph.contacts)
              {
                'Id': contact.id,
                'Name': contact.name,
                'Phone': contact.phone,
                'CompanyName': graph.company(contact.companyId).name,
              },
          ].where(
            (row) => fakeMatches(row, term, ['Name', 'Phone', 'CompanyName']),
          );
      final items = fakePage(rows.toList(), page: page)['Items'] as List;
      return [
        for (final item in items)
          InviteContact.fromJson(item as Map<String, dynamic>),
      ];
    },
    module: AppModule.referral,
    right: ModuleRight.add,
  );

  @override
  Future<RewardMoment?> pendingReward() => _backend.run('Referral reward', () {
    final row = _ledger.wallet.rows
        .where((w) => jsonBool(w['Celebrate']) && !jsonBool(w['Seen']))
        .firstOrNull;
    if (row == null) return null;
    final friend = _ledger.referrals.byIdOrNull(
      jsonInt(row['ReferralId']) ?? 0,
    );
    return RewardMoment.fromJson({
      'Id': row['Id'],
      'Name': row['Name'],
      'NameBn': row['NameBn'],
      'Amount': row['Amount'],
      'HoldHours': friend == null
          ? 0
          : _ledger.referralJson(friend)['HoldHours'] ?? 0,
      'Overview': _ledger.overviewJson(),
    });
  }, module: AppModule.referral);

  @override
  Future<void> markRewardSeen(int id) =>
      _backend.run('Referral reward seen', () {
        _ledger.wallet.update(id, {'Seen': true});
      }, module: AppModule.referral);
}
