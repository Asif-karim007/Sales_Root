import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';

/// Bulk SMS and email campaigns, and the SMS credit balance. Sending more
/// than the balance covers fails with a 402 for `QuotaKind.smsCredits`.
abstract interface class CampaignRepository {
  /// Scheduled campaigns first, soonest on top, then the rest newest first.
  Future<PageResult<Campaign>> list({int page = 1});

  Future<Campaign> get(int id);

  Future<MessagingBalance> balance();

  Future<List<Audience>> audiences();

  Future<List<MessageTemplate>> smsTemplates();

  Future<Campaign> sendSms(SmsCampaignInput input);

  /// Sends [message] to the signed-in user's own number.
  Future<void> testSms(String message);

  Future<Campaign> sendEmail(EmailCampaignInput input);

  /// Resends to the numbers that were switched off.
  Future<Campaign> retryFailed(int id);

  Future<Campaign> cancel(int id);

  Future<List<CreditPack>> creditPacks();

  Future<MessagingBalance> buyCredits(int packId);
}
