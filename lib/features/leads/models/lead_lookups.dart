import 'package:salesroot/core/utils/json_fields.dart';

/// A choice with a label in both languages: an owner or a lost reason.
class LeadOption {
  const LeadOption({required this.id, required this.name, this.subtitle});

  final String id;
  final LocalizedName name;
  final String? subtitle;

  /// A workspace member, from `GET workspaces/members`.
  factory LeadOption.member(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return LeadOption(
      id: jsonId(json['id']) ?? '',
      name: LocalizedName(name, name),
      subtitle: json['designation'] as String?,
    );
  }

  /// A `{key, en, bn}` entry of the workspace pack, such as a lost reason.
  factory LeadOption.pack(Map<String, dynamic> json) => LeadOption(
    id: json['key'] as String? ?? '',
    name: LocalizedName.of(json),
  );
}

/// Where a lead came from. The server takes any text; these are the keys the
/// app offers and names.
enum LeadSource {
  manual('manual'),
  phone('phone'),
  walkIn('walk_in'),
  referral('referral'),
  facebook('facebook'),
  whatsapp('whatsapp'),
  website('website'),
  card('card');

  const LeadSource(this.wire);

  final String wire;

  static const _aliases = {
    'phone call': phone,
    'call': phone,
    'sms': phone,
    'visiting card': card,
    'business card': card,
    'messenger': facebook,
    'walk-in': walkIn,
  };

  /// The source for a key, or for a label another screen passes along.
  static LeadSource? fromAny(String? value) {
    final key = value?.trim().toLowerCase() ?? '';
    for (final source in values) {
      if (source.wire == key || source.name.toLowerCase() == key) {
        return source;
      }
    }
    return _aliases[key];
  }
}

enum LeadFieldType { text, number, select }

/// A custom lead field from the workspace pack; its value lives in the
/// lead's `custom` map under [key].
class LeadField {
  const LeadField({
    required this.key,
    required this.label,
    this.type = LeadFieldType.text,
    this.options = const [],
  });

  final String key;
  final LocalizedName label;
  final LeadFieldType type;
  final List<String> options;

  factory LeadField.fromJson(Map<String, dynamic> json) => LeadField(
    key: json['key'] as String? ?? '',
    label: LocalizedName.of(json),
    type: switch (json['type']) {
      'number' => LeadFieldType.number,
      'select' => LeadFieldType.select,
      _ => LeadFieldType.text,
    },
    options: jsonStrings(json['options']),
  );
}

class LeadLookupCompany {
  const LeadLookupCompany({required this.id, required this.name, this.area});

  final String id;
  final String name;
  final String? area;

  factory LeadLookupCompany.fromJson(Map<String, dynamic> json) =>
      LeadLookupCompany(
        id: jsonId(json['id']) ?? '',
        name: json['name'] as String? ?? '',
        area: json['area'] as String?,
      );
}

class LeadLookupContact {
  const LeadLookupContact({
    required this.id,
    required this.name,
    this.companyId,
    this.companyName,
    this.designation,
    this.mobile,
  });

  final String id;
  final String name;
  final String? companyId;
  final String? companyName;
  final String? designation;
  final String? mobile;

  factory LeadLookupContact.fromJson(Map<String, dynamic> json) =>
      LeadLookupContact(
        id: jsonId(json['id']) ?? '',
        name: json['name'] as String? ?? '',
        companyId: jsonId(json['companyId']),
        companyName: json['companyName'] as String?,
        designation: json['designation'] as String?,
        mobile: json['phone'] as String?,
      );
}

/// The option lists the lead screens need, fetched once per workspace:
/// the members who can own a lead, and the pack's lost reasons and custom
/// fields. [currentMemberId] is the user's own membership.
class LeadLookups {
  const LeadLookups({
    this.currentMemberId,
    this.owners = const [],
    this.lostReasons = const [],
    this.fields = const [],
  });

  final String? currentMemberId;
  final List<LeadOption> owners;
  final List<LeadOption> lostReasons;
  final List<LeadField> fields;

  LeadOption? lostReason(String? key) {
    for (final reason in lostReasons) {
      if (reason.id == key) return reason;
    }
    return null;
  }

  LeadField? field(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// [members] is `GET workspaces/members`; [workspace] is
  /// `GET workspaces/current`, whose `settings.pack` holds the lists.
  factory LeadLookups.fromJson({
    required List<dynamic> members,
    required Map<String, dynamic> workspace,
    String? currentMemberId,
  }) {
    final pack = jsonMap(jsonMap(workspace['settings'])['pack']);
    return LeadLookups(
      currentMemberId: currentMemberId,
      owners: [
        for (final member in members)
          if (member is Map<String, dynamic> && member['status'] == 'active')
            LeadOption.member(member),
      ],
      lostReasons: jsonList(pack['lostReasons'], LeadOption.pack),
      fields: jsonList(pack['leadFields'], LeadField.fromJson),
    );
  }
}
