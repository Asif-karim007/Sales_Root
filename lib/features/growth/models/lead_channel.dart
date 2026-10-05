import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum ChannelKind {
  facebook,
  whatsapp,
  messenger,
  website,
  hostedForm,
  email,
  linkedin,
  googleAds,
}

enum ChannelStatus { connected, available, soon }

/// What an integration connects: a Meta Page (lead forms and Messenger), a
/// WhatsApp Cloud number or an SMS gateway.
enum IntegrationProvider {
  meta('meta'),
  whatsapp('whatsapp'),
  gateway('gateway');

  const IntegrationProvider(this.wire);

  final String wire;

  static IntegrationProvider? fromWire(String? value) =>
      values.where((provider) => provider.wire == value).firstOrNull;
}

/// One row of `GET integrations`.
class Integration {
  const Integration({
    required this.id,
    required this.provider,
    this.displayName,
    this.connectedAt,
  });

  final String id;
  final IntegrationProvider? provider;
  final String? displayName;
  final DateTime? connectedAt;

  factory Integration.fromJson(Map<String, dynamic> json) => Integration(
    id: jsonId(json['id']) ?? '',
    provider: IntegrationProvider.fromWire(
      json['provider'] as String? ?? json['kind'] as String?,
    ),
    displayName:
        json['displayName'] as String? ?? json['displayPhone'] as String?,
    connectedAt: jsonDate(json['createdAt']),
  );
}

/// A hosted lead form (`GET forms`), shared as a link or embedded on a site.
class LeadForm {
  const LeadForm({
    required this.id,
    required this.name,
    required this.isActive,
    this.slug,
  });

  final String id;
  final String name;
  final String? slug;
  final bool isActive;

  /// The public page at `/f/{slug}`, outside the versioned API.
  String? get shareUrl {
    final slug = this.slug;
    if (slug == null || slug.isEmpty) return null;
    return Uri.parse(ApiConfig.baseUrl).resolve('/f/$slug').toString();
  }

  String? get embedCode {
    final url = shareUrl;
    return url == null ? null : '<script src="$url/embed.js" async></script>';
  }

  factory LeadForm.fromJson(Map<String, dynamic> json) => LeadForm(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String?,
    isActive: json['isActive'] != false,
  );
}

/// `FormUpsert`. The server makes the slug when none is given.
class LeadFormInput {
  const LeadFormInput({required this.name, this.isActive = true, this.fields});

  final String name;
  final bool isActive;

  /// The questions, as the form builder stores them; null keeps them.
  final List<Map<String, dynamic>>? fields;

  /// A new form asking for a name, a phone number and a message.
  static const enquiryFields = [
    {'key': 'name', 'type': 'text', 'required': true},
    {'key': 'phone', 'type': 'phone', 'required': true},
    {'key': 'message', 'type': 'textarea', 'required': false},
  ];

  Map<String, dynamic> toJson() =>
      {'name': name.trim(), 'isActive': isActive, 'fields': fields}
        ..removeWhere((_, value) => value == null);
}

/// `WhatsAppConnect`: a WhatsApp Cloud API number from Meta Business.
class WhatsAppConnectInput {
  const WhatsAppConnectInput({
    required this.phoneNumberId,
    required this.wabaId,
    required this.accessToken,
    this.displayPhone,
  });

  final String phoneNumberId;
  final String wabaId;
  final String accessToken;
  final String? displayPhone;

  Map<String, dynamic> toJson() => {
    'phoneNumberId': phoneNumberId.trim(),
    'wabaId': wabaId.trim(),
    'accessToken': accessToken.trim(),
    'displayPhone': displayPhone?.trim(),
  }..removeWhere((_, value) => value == null || value == '');
}

/// One place leads come in from, built from the integrations and forms.
class LeadChannel {
  const LeadChannel({
    required this.kind,
    required this.status,
    this.account,
    this.integration,
    this.form,
    this.formCount = 0,
  });

  final ChannelKind kind;
  final ChannelStatus status;

  /// The Page name, number or form name the channel is tied to.
  final String? account;
  final Integration? integration;

  /// The form a website or hosted channel shares.
  final LeadForm? form;
  final int formCount;

  bool get isConnected => status == ChannelStatus.connected;

  String? get embedCode => kind == ChannelKind.website ? form?.embedCode : null;

  String? get shareUrl =>
      kind == ChannelKind.hostedForm ? form?.shareUrl : null;

  /// Every channel, connected or not, from what the server has.
  static List<LeadChannel> from(
    List<Integration> integrations,
    List<LeadForm> forms,
  ) {
    Integration? find(IntegrationProvider provider) =>
        integrations.where((i) => i.provider == provider).firstOrNull;
    final meta = find(IntegrationProvider.meta);
    final whatsapp = find(IntegrationProvider.whatsapp);
    final active = forms.where((f) => f.isActive).toList();
    final form = active.firstOrNull ?? forms.firstOrNull;
    LeadChannel connection(ChannelKind kind, Integration? integration) =>
        LeadChannel(
          kind: kind,
          status: integration == null
              ? ChannelStatus.available
              : ChannelStatus.connected,
          account: integration?.displayName,
          integration: integration,
        );
    LeadChannel hosted(ChannelKind kind) => LeadChannel(
      kind: kind,
      status: active.isEmpty
          ? ChannelStatus.available
          : ChannelStatus.connected,
      account: form?.name,
      form: form,
      formCount: active.length,
    );
    return [
      connection(ChannelKind.facebook, meta),
      connection(ChannelKind.whatsapp, whatsapp),
      connection(ChannelKind.messenger, meta),
      hosted(ChannelKind.website),
      hosted(ChannelKind.hostedForm),
      for (final kind in const [
        ChannelKind.email,
        ChannelKind.linkedin,
        ChannelKind.googleAds,
      ])
        LeadChannel(kind: kind, status: ChannelStatus.soon),
    ];
  }
}
