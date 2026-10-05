import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/campaign_repository.dart';
import 'package:salesroot/features/growth/data/growth_api.dart';
import 'package:salesroot/features/growth/models/campaign.dart';

class ApiCampaignRepository implements CampaignRepository {
  ApiCampaignRepository(this._api);

  final GrowthApi _api;

  @override
  Future<PageResult<Campaign>> list() async {
    final json = await apiRequest('Campaigns', _api.campaigns);
    return json is Map<String, dynamic>
        ? PageResult.fromJson(json, Campaign.fromJson)
        : PageResult.all(jsonList(json, Campaign.fromJson));
  }

  @override
  Future<Campaign> get(String id) async => Campaign.fromJson(
    jsonMap(await apiRequest('Campaign', () => _api.campaign(id))),
  );

  @override
  Future<List<Audience>> audiences(CampaignChannel channel) => Future.wait([
    for (final segment in AudienceSegment.values) _preview(channel, segment),
  ]);

  @override
  Future<Campaign> send(CampaignInput input) async {
    final json = await apiRequest(
      'Campaign send',
      () => _api.createCampaign(input.toJson()),
    );
    return Campaign.fromJson({...input.toJson(), ...jsonMap(json)});
  }

  @override
  Future<Campaign> cancel(String id) async {
    await apiRequest('Campaign cancel', () => _api.cancelCampaign(id));
    return get(id);
  }

  Future<Audience> _preview(
    CampaignChannel channel,
    AudienceSegment segment,
  ) async {
    final json = await apiRequest(
      'Campaign preview',
      () => _api.preview(
        CampaignInput(
          name: segment.name,
          channel: channel,
          segment: segment,
        ).toJson(),
      ),
    );
    return Audience.fromPreview(segment, jsonMap(json));
  }
}
