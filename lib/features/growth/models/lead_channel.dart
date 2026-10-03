import 'package:salesroot/core/utils/json_fields.dart';

enum ChannelKind {
  facebook('Facebook'),
  whatsapp('WhatsApp'),
  messenger('Messenger'),
  website('Website'),
  hostedForm('HostedForm'),
  email('Email'),
  linkedin('LinkedIn'),
  googleAds('GoogleAds');

  const ChannelKind(this.wire);

  final String wire;

  static ChannelKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => ChannelKind.website,
  );
}

enum ChannelStatus {
  connected('Connected'),
  available('Available'),
  soon('Soon');

  const ChannelStatus(this.wire);

  final String wire;

  static ChannelStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => ChannelStatus.available,
  );
}

/// One place leads come in from: a Page, a number, a form or a mailbox.
class LeadChannel {
  const LeadChannel({
    required this.id,
    required this.kind,
    required this.status,
    this.account,
    this.formCount = 0,
    this.leadCount = 0,
    this.leadsThisWeek = 0,
    this.embedCode,
    this.shareUrl,
  });

  final int id;
  final ChannelKind kind;
  final ChannelStatus status;

  /// The Page name, number, address or URL the channel is tied to.
  final String? account;
  final int formCount;
  final int leadCount;
  final int leadsThisWeek;
  final String? embedCode;
  final String? shareUrl;

  bool get isConnected => status == ChannelStatus.connected;

  factory LeadChannel.fromJson(Map<String, dynamic> json) => LeadChannel(
    id: jsonInt(json['Id']) ?? 0,
    kind: ChannelKind.fromWire(json['Kind'] as String?),
    status: ChannelStatus.fromWire(json['Status'] as String?),
    account: json['Account'] as String?,
    formCount: jsonInt(json['FormCount']) ?? 0,
    leadCount: jsonInt(json['LeadCount']) ?? 0,
    leadsThisWeek: jsonInt(json['LeadsThisWeek']) ?? 0,
    embedCode: json['EmbedCode'] as String?,
    shareUrl: json['ShareUrl'] as String?,
  );
}

class FacebookPage {
  const FacebookPage({
    required this.id,
    required this.name,
    required this.adminName,
    this.tokenOk = true,
    this.followers = 0,
  });

  final int id;
  final String name;
  final String adminName;
  final bool tokenOk;
  final int followers;

  factory FacebookPage.fromJson(Map<String, dynamic> json) => FacebookPage(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    adminName: json['AdminName'] as String? ?? '',
    tokenOk: json['TokenOk'] != false,
    followers: jsonInt(json['Followers']) ?? 0,
  );
}

class LeadForm {
  const LeadForm({
    required this.id,
    required this.name,
    this.campaign,
    this.leadCount = 0,
    this.enabled = false,
    this.fields = const [],
  });

  final int id;
  final String name;
  final String? campaign;
  final int leadCount;
  final bool enabled;

  /// The form's question keys, e.g. `full_name`, `roof_size`.
  final List<String> fields;

  LeadForm copyWith({bool? enabled}) => LeadForm(
    id: id,
    name: name,
    campaign: campaign,
    leadCount: leadCount,
    enabled: enabled ?? this.enabled,
    fields: fields,
  );

  factory LeadForm.fromJson(Map<String, dynamic> json) => LeadForm(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    campaign: json['Campaign'] as String?,
    leadCount: jsonInt(json['LeadCount']) ?? 0,
    enabled: jsonBool(json['Enabled']),
    fields: jsonStrings(json['Fields']),
  );
}

/// The lead field a form question fills.
enum LeadField {
  name('Name'),
  mobile('Mobile'),
  email('Email'),
  area('Area'),
  company('Company'),
  note('Note'),
  custom('Custom'),
  skip('Skip');

  const LeadField(this.wire);

  final String wire;

  static LeadField fromWire(String? value) => values.firstWhere(
    (field) => field.wire == value,
    orElse: () => LeadField.custom,
  );

  /// The usual target for a Meta form question key.
  static LeadField guess(String key) => switch (key) {
    'full_name' || 'first_name' || 'name' => LeadField.name,
    'phone_number' || 'phone' || 'mobile' => LeadField.mobile,
    'email' => LeadField.email,
    'city' || 'area' || 'district' => LeadField.area,
    'company_name' || 'company' || 'business_name' => LeadField.company,
    'message' || 'comments' => LeadField.note,
    _ => LeadField.custom,
  };
}

class FieldMapping {
  const FieldMapping({required this.field, required this.target});

  final String field;
  final LeadField target;

  factory FieldMapping.fromJson(Map<String, dynamic> json) => FieldMapping(
    field: json['Field'] as String? ?? '',
    target: LeadField.fromWire(json['Target'] as String?),
  );

  Map<String, dynamic> toJson() => {'Field': field, 'Target': target.wire};
}

enum LeadDestination {
  inbox('Inbox'),
  rules('Rules');

  const LeadDestination(this.wire);

  final String wire;

  static LeadDestination fromWire(String? value) => values.firstWhere(
    (destination) => destination.wire == value,
    orElse: () => LeadDestination.rules,
  );
}

/// The Facebook connection: the Page, its lead forms and how their answers
/// map onto lead fields.
class FacebookSetup {
  const FacebookSetup({
    this.page,
    this.forms = const [],
    this.mappings = const [],
    this.destination = LeadDestination.rules,
  });

  final FacebookPage? page;
  final List<LeadForm> forms;
  final List<FieldMapping> mappings;
  final LeadDestination destination;

  bool get isConnected => page != null;

  factory FacebookSetup.fromJson(Map<String, dynamic> json) => FacebookSetup(
    page: jsonObject(json['Page'], FacebookPage.fromJson),
    forms: jsonList(json['Forms'], LeadForm.fromJson),
    mappings: jsonList(json['Mappings'], FieldMapping.fromJson),
    destination: LeadDestination.fromWire(json['Destination'] as String?),
  );
}

class FacebookSetupInput {
  const FacebookSetupInput({
    required this.pageId,
    required this.formIds,
    required this.mappings,
    required this.destination,
  });

  final int pageId;
  final List<int> formIds;
  final List<FieldMapping> mappings;
  final LeadDestination destination;

  Map<String, dynamic> toJson() => {
    'PageId': pageId,
    'FormIds': formIds,
    'Mappings': [for (final mapping in mappings) mapping.toJson()],
    'Destination': destination.wire,
  };
}
