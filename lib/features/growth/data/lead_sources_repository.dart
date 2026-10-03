import 'package:salesroot/features/growth/models/lead_channel.dart';

/// The channels leads arrive from, and the Facebook lead-form connection.
abstract interface class LeadSourcesRepository {
  Future<List<LeadChannel>> channels();

  Future<LeadChannel> connect(int channelId);

  Future<LeadChannel> disconnect(int channelId);

  Future<FacebookSetup> facebook();

  /// The Pages the Facebook account manages, after Meta sign-in.
  Future<List<FacebookPage>> facebookPages();

  Future<List<LeadForm>> facebookForms(int pageId);

  Future<FacebookSetup> saveFacebook(FacebookSetupInput input);
}
