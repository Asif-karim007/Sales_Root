import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/campaign.dart';

/// Bulk SMS and email campaigns. Sending more than the SMS credits cover
/// fails with a 402.
abstract interface class CampaignRepository {
  Future<PageResult<Campaign>> list();

  Future<Campaign> get(String id);

  /// How many people each segment reaches on [channel] right now.
  Future<List<Audience>> audiences(CampaignChannel channel);

  Future<Campaign> send(CampaignInput input);

  Future<Campaign> cancel(String id);
}
