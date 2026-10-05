import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/models/referral.dart';

abstract interface class ReferralRepository {
  Future<ReferralOverview> overview();

  Future<PageResult<Referral>> list(int page);

  Future<PageResult<WalletEntry>> wallet(int page);

  /// Whether [contact], a phone or an email, can be referred.
  Future<InviteEligibility> check(String contact);

  /// Records an invite; with [sendSms] the server also texts the link.
  Future<InviteResult> invite(String contact, {required bool sendSms});

  /// CRM contacts with a phone, to invite from.
  Future<List<InviteContact>> contacts(String term, int page);
}
