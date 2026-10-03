import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/campaign_fixtures.dart';
import 'package:salesroot/features/growth/data/campaign_repository.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/models/sms_count.dart';

class FakeCampaignRepository implements CampaignRepository {
  FakeCampaignRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _campaigns =>
      _backend.table(growthCampaignsTable, campaignFixtures);

  FakeTable get _balance => _backend.table(growthBalanceTable, balanceFixtures);

  FakeTable get _templates =>
      _backend.table(growthSmsTemplatesTable, smsTemplateFixtures);

  Map<String, dynamic> get _wallet => _balance.rows.isEmpty
      ? _balance.insert(balanceFixtures(_backend.graph).first)
      : _balance.rows.first;

  int get _credits => jsonInt(_wallet['SmsCredits']) ?? 0;

  @override
  Future<PageResult<Campaign>> list({int page = 1}) => _backend.run(
    'Campaigns',
    () {
      final rows = [..._campaigns.rows]..sort(_newestFirst);
      return PageResult.fromJson(fakePage(rows, page: page), Campaign.fromJson);
    },
    module: AppModule.campaign,
  );

  @override
  Future<Campaign> get(int id) => _backend.run(
    'Campaign',
    () => Campaign.fromJson(_campaigns.byId(id)),
    module: AppModule.campaign,
  );

  @override
  Future<MessagingBalance> balance() => _backend.run(
    'Messaging balance',
    () => MessagingBalance.fromJson(_wallet),
    module: AppModule.campaign,
  );

  @override
  Future<List<Audience>> audiences() => _backend.run(
    'Campaign audiences',
    _audiences,
    module: AppModule.campaign,
  );

  List<Audience> _audiences() {
    final graph = _backend.graph;
    final won = {
      for (final lead in graph.leads)
        if (lead.stageId == 5) lead.companyId,
    };
    int people(Iterable<int> companyIds) =>
        [for (final id in companyIds) ...graph.contactsOf(id)].length;
    final dealers = [
      for (final c in graph.companies)
        if (c.industry == 'Retail' || c.industry == 'Electronics') c.id,
    ];
    final counts = {
      AudienceSegment.overdueCustomers: people(won.where((id) => id % 3 != 0)),
      AudienceSegment.customers: people(won),
      AudienceSegment.dealers: people(dealers),
      AudienceSegment.hotLeads: graph.leads
          .where((l) => l.hot && l.isOpen)
          .length,
      AudienceSegment.interestedLeads: graph.leads
          .where((l) => l.stageId == 3)
          .length,
      AudienceSegment.openLeads: graph.leads.where((l) => l.isOpen).length,
    };
    return [
      for (final MapEntry(key: segment, value: count) in counts.entries)
        Audience.fromJson({
          'Segment': segment.wire,
          'Count': count,
          'DoNotContact': count ~/ 16,
        }),
    ];
  }

  Audience _audience(AudienceSegment segment) =>
      _audiences().firstWhere((a) => a.segment == segment);

  @override
  Future<List<MessageTemplate>> smsTemplates() => _backend.run(
    'SMS templates',
    () => [for (final row in _templates.rows) MessageTemplate.fromJson(row)],
    module: AppModule.campaign,
  );

  @override
  Future<Campaign> sendSms(SmsCampaignInput input) => _backend.run(
    'Send SMS campaign',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Message']);
      final reach = _audience(
        input.segment,
      ).reach(excludeDoNotContact: input.excludeDoNotContact);
      if (reach <= 0) {
        throw const ApiFailure(400, 'Nobody matches this audience');
      }
      final needed = SmsCount.of(input.message).segments * reach;
      _spend(needed);
      final scheduled = input.scheduleAt != null;
      final wrong = (reach * 0.026).round();
      final off = (reach * 0.014).round();
      final row = _campaigns.insert({
        ...body,
        'Channel': CampaignChannel.sms.wire,
        'Status': scheduled
            ? CampaignStatus.scheduled.wire
            : CampaignStatus.done.wire,
        'Recipients': reach,
        'CreditsUsed': needed,
        'ScheduledAt': body['ScheduleAt'],
        if (!scheduled) ...{
          'SentAt': jsonUtc(DateTime.now()),
          'Sent': reach,
          'Delivered': reach - wrong - off,
          'WrongNumber': wrong,
          'SwitchedOff': off,
        },
      });
      return Campaign.fromJson(row);
    },
    module: AppModule.campaign,
    right: ModuleRight.add,
    quota: QuotaKind.smsCredits,
  );

  @override
  Future<void> testSms(String message) => _backend.run(
    'Test SMS',
    () {
      fakeRequire({'Message': message}, ['Message']);
      _spend(SmsCount.of(message).segments);
    },
    module: AppModule.campaign,
    right: ModuleRight.add,
    quota: QuotaKind.smsCredits,
  );

  @override
  Future<Campaign> sendEmail(EmailCampaignInput input) => _backend.run(
    'Send email campaign',
    () {
      final body = input.toJson();
      fakeRequire(body, ['Subject', 'Body']);
      final reach = _audience(input.segment).count;
      if (reach <= 0) {
        throw const ApiFailure(400, 'Nobody matches this audience');
      }
      final used = jsonInt(_wallet['EmailUsed']) ?? 0;
      final limit = jsonInt(_wallet['EmailLimit']) ?? 0;
      if (used + reach > limit) {
        throw const ApiFailure(402, 'This month’s email limit is used up');
      }
      _balance.update(1, {'EmailUsed': used + reach});
      final row = _campaigns.insert({
        ...body,
        'Name': input.subject.trim(),
        'Channel': CampaignChannel.email.wire,
        'Status': CampaignStatus.done.wire,
        'Recipients': reach,
        'SentAt': jsonUtc(DateTime.now()),
        'Sent': reach,
        'Delivered': reach,
      });
      return Campaign.fromJson(row);
    },
    module: AppModule.campaign,
    right: ModuleRight.add,
  );

  @override
  Future<Campaign> retryFailed(int id) => _backend.run(
    'Retry campaign',
    () {
      final row = _campaigns.byId(id);
      final off = jsonInt(row['SwitchedOff']) ?? 0;
      if (off == 0) {
        throw const ApiFailure(400, 'Nothing left to retry');
      }
      final segments = SmsCount.of('${row['Message'] ?? ''}').segments;
      _spend(off * (segments == 0 ? 1 : segments));
      final recovered = (off * 0.7).round();
      return Campaign.fromJson(
        _campaigns.update(id, {
          'Delivered': (jsonInt(row['Delivered']) ?? 0) + recovered,
          'SwitchedOff': off - recovered,
        }),
      );
    },
    module: AppModule.campaign,
    right: ModuleRight.add,
    quota: QuotaKind.smsCredits,
  );

  @override
  Future<Campaign> cancel(int id) => _backend.run(
    'Cancel campaign',
    () {
      final row = _campaigns.byId(id);
      if (row['Status'] != CampaignStatus.scheduled.wire) {
        throw const ApiFailure(409, 'This campaign has already gone out');
      }
      if (row['Channel'] == CampaignChannel.sms.wire) {
        _balance.update(1, {
          'SmsCredits': _credits + (jsonInt(row['CreditsUsed']) ?? 0),
        });
      }
      return Campaign.fromJson(
        _campaigns.update(id, {'Status': CampaignStatus.cancelled.wire}),
      );
    },
    module: AppModule.campaign,
    right: ModuleRight.delete,
  );

  @override
  Future<List<CreditPack>> creditPacks() => _backend.run(
    'Credit packs',
    () => [for (final pack in creditPackFixtures) CreditPack.fromJson(pack)],
    module: AppModule.campaign,
  );

  @override
  Future<MessagingBalance> buyCredits(int packId) => _backend.run(
    'Buy SMS credits',
    () {
      final pack = creditPackFixtures.firstWhere(
        (p) => p['Id'] == packId,
        orElse: () => throw const ApiFailure(404, 'Pack not found'),
      );
      return MessagingBalance.fromJson(
        _balance.update(1, {
          'SmsCredits': _credits + (jsonInt(pack['Credits']) ?? 0),
        }),
      );
    },
    module: AppModule.campaign,
    right: ModuleRight.add,
  );

  void _spend(int credits) {
    final have = _credits;
    if (credits > have) {
      throw ApiFailure(
        402,
        'Not enough SMS credits: $credits needed, $have left',
        quota: QuotaKind.smsCredits,
      );
    }
    _balance.update(1, {
      'SmsCredits': have - credits,
      'SmsUsedThisMonth': (jsonInt(_wallet['SmsUsedThisMonth']) ?? 0) + credits,
    });
  }

  static int _newestFirst(Map<String, dynamic> a, Map<String, dynamic> b) {
    final scheduled = _isScheduled(b).compareTo(_isScheduled(a));
    if (scheduled != 0) return scheduled;
    if (_isScheduled(a) == 1) return _when(a).compareTo(_when(b));
    return _when(b).compareTo(_when(a));
  }

  static int _isScheduled(Map<String, dynamic> row) =>
      row['Status'] == CampaignStatus.scheduled.wire ? 1 : 0;

  static String _when(Map<String, dynamic> row) =>
      '${row['SentAt'] ?? row['ScheduledAt'] ?? ''}';
}
