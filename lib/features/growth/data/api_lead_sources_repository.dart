import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/growth_api.dart';
import 'package:salesroot/features/growth/data/lead_sources_repository.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';

class ApiLeadSourcesRepository implements LeadSourcesRepository {
  ApiLeadSourcesRepository(this._api);

  final GrowthApi _api;

  @override
  Future<List<Integration>> integrations() async => jsonList(
    await apiRequest('Integrations', _api.integrations),
    Integration.fromJson,
  );

  @override
  Future<List<LeadForm>> forms() async =>
      jsonList(await apiRequest('Lead forms', _api.forms), LeadForm.fromJson);

  @override
  Future<LeadForm> createForm(LeadFormInput input) async {
    final json = await apiRequest(
      'Lead form create',
      () => _api.createForm(input.toJson()),
    );
    return LeadForm.fromJson({...input.toJson(), ...jsonMap(json)});
  }

  @override
  Future<LeadForm> updateForm(String id, LeadFormInput input) async {
    final json = await apiRequest(
      'Lead form update',
      () => _api.updateForm(id, input.toJson()),
    );
    return LeadForm.fromJson({'id': id, ...input.toJson(), ...jsonMap(json)});
  }

  @override
  Future<Integration> connectWhatsApp(WhatsAppConnectInput input) async {
    final json = await apiRequest(
      'WhatsApp connect',
      () => _api.connectWhatsApp(input.toJson()),
    );
    return Integration.fromJson({
      'provider': IntegrationProvider.whatsapp.wire,
      'displayName': input.displayPhone,
      ...jsonMap(json),
    });
  }

  @override
  Future<void> disconnect(String integrationId) => apiRequest(
    'Integration disconnect',
    () => _api.deleteIntegration(integrationId),
  );
}
