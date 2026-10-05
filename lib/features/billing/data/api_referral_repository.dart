import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/data/billing_api.dart';
import 'package:salesroot/features/billing/data/referral_repository.dart';
import 'package:salesroot/features/billing/models/referral.dart';

class ApiReferralRepository implements ReferralRepository {
  ApiReferralRepository(this._api, {required this.today});

  final BillingApi _api;
  final DateTime Function() today;

  @override
  Future<ReferralOverview> overview() async {
    final json = await apiRequest(
      'Referrals',
      () => _api.referrals(pageQuery(1, size: 5)),
    );
    return ReferralOverview.fromJson(jsonMap(json));
  }

  @override
  Future<PageResult<Referral>> list(int page) async {
    final json = await apiRequest(
      'Referral list',
      () => _api.referrals(pageQuery(page)),
    );
    return PageResult.fromJson(
      jsonMap(jsonMap(json)['history']),
      Referral.fromJson,
    );
  }

  /// The server needs a date range; the whole history is asked for.
  @override
  Future<PageResult<WalletEntry>> wallet(int page) async {
    final now = today();
    final to = DateTime(now.year, now.month, now.day + 1);
    final json = await apiRequest(
      'Wallet',
      () => _api.walletTransactions({
        ...pageQuery(page),
        'from': '2020-01-01',
        'to': to.toIso8601String().substring(0, 10),
      }),
    );
    return PageResult.fromJson(jsonMap(json), WalletEntry.fromJson);
  }

  @override
  Future<InviteEligibility> check(String contact) async {
    final json = await apiRequest(
      'Referral check',
      () => _api.checkReferral(_contact(contact)),
    );
    return InviteEligibility.fromWire(jsonMap(json)['status'] as String?);
  }

  @override
  Future<InviteResult> invite(String contact, {required bool sendSms}) async {
    final json = await apiRequest(
      'Referral invite',
      () => _api.refer({
        'phone': null,
        'email': null,
        ..._contact(contact),
        'channel': sendSms ? 'sms' : 'copy',
        'name': null,
      }),
    );
    return InviteResult.fromJson(jsonMap(json));
  }

  @override
  Future<List<InviteContact>> contacts(String term, int page) async {
    final json = await apiRequest(
      'Invite contacts',
      () => _api.contacts({
        ...pageQuery(page),
        if (term.trim().isNotEmpty) 'q': term.trim(),
      }),
    );
    return [
      for (final contact in PageResult.fromJson(
        jsonMap(json),
        InviteContact.fromJson,
      ).items)
        if (contact.phone.isNotEmpty) contact,
    ];
  }

  static Map<String, String> _contact(String contact) =>
      contact.contains('@') ? {'email': contact} : {'phone': contact};
}
