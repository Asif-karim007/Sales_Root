import 'package:salesroot/features/growth/models/lead_channel.dart';

/// The channels leads arrive from: Meta and WhatsApp connections and the
/// hosted lead forms.
abstract interface class LeadSourcesRepository {
  Future<List<Integration>> integrations();

  Future<List<LeadForm>> forms();

  Future<LeadForm> createForm(LeadFormInput input);

  Future<LeadForm> updateForm(String id, LeadFormInput input);

  Future<Integration> connectWhatsApp(WhatsAppConnectInput input);

  Future<void> disconnect(String integrationId);
}
