import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

enum InviteChannel { phone, email }

/// An invitation that has not been accepted yet.
class Invite {
  const Invite({
    required this.id,
    required this.code,
    required this.link,
    this.name,
    this.phone,
    this.email,
    this.role = WorkspaceRole.member,
    this.managerId,
    this.managerName,
    this.level,
    this.fieldForce = false,
    this.teamOnlyCapture = false,
    this.sentAt,
    this.sentDaysAgo = 0,
    this.expiresInDays = 7,
  });

  final int id;
  final String code;

  /// The accept-invite link the server built for [code].
  final String link;
  final String? name;
  final String? phone;
  final String? email;
  final WorkspaceRole role;
  final int? managerId;
  final LocalizedName? managerName;

  /// Null when the invitee picks their own level.
  final ExperienceLevel? level;
  final bool fieldForce;
  final bool teamOnlyCapture;
  final DateTime? sentAt;

  /// Server-computed, so the device clock never decides it.
  final int sentDaysAgo;
  final int expiresInDays;

  InviteChannel get channel =>
      phone == null ? InviteChannel.email : InviteChannel.phone;

  /// The name, else the number or address the invite went to.
  String get label {
    final name = this.name;
    if (name != null && name.isNotEmpty) return name;
    return phone ?? email ?? '';
  }

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String? ?? '',
    link: json['Link'] as String? ?? '',
    name: json['Name'] as String?,
    phone: json['Phone'] as String?,
    email: json['Email'] as String?,
    role: WorkspaceRole.fromWire(json['Role'] as String?),
    managerId: jsonInt(json['ManagerId']),
    managerName: json['ManagerName'] == null
        ? null
        : LocalizedName(
            json['ManagerName'] as String? ?? '',
            json['ManagerNameBn'] as String? ?? '',
          ),
    level: ExperienceLevel.fromWire(json['Level'] as String?),
    fieldForce: jsonBool(json['FieldForce']),
    teamOnlyCapture: jsonBool(json['TeamOnlyCapture']),
    sentAt: jsonDate(json['SentAt']),
    sentDaysAgo: jsonInt(json['SentDaysAgo']) ?? 0,
    expiresInDays: jsonInt(json['ExpiresInDays']) ?? 7,
  );
}

class InviteInput {
  const InviteInput({
    required this.channel,
    this.phone,
    this.email,
    this.name,
    this.role = WorkspaceRole.member,
    this.managerId,
    this.level,
    this.fieldForce = false,
    this.teamOnlyCapture = false,
  });

  final InviteChannel channel;
  final String? phone;
  final String? email;
  final String? name;
  final WorkspaceRole role;
  final int? managerId;
  final ExperienceLevel? level;
  final bool fieldForce;
  final bool teamOnlyCapture;

  Map<String, dynamic> toJson() {
    String? clean(String? value) {
      final text = value?.trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return {
      'Phone': channel == InviteChannel.phone
          ? clean(phone)?.replaceAll(RegExp(r'[\s-]'), '')
          : null,
      'Email': channel == InviteChannel.email ? clean(email) : null,
      'Name': clean(name),
      'Role': role.wire,
      'ManagerId': managerId,
      'Level': level?.wire,
      'FieldForce': fieldForce,
      'TeamOnlyCapture': teamOnlyCapture,
    }..removeWhere((_, value) => value == null);
  }
}

/// Extra users the owner can add when every seat is taken.
class SeatPack {
  const SeatPack({
    required this.seats,
    required this.pricePerMonth,
    required this.proratedToday,
  });

  final int seats;
  final int pricePerMonth;
  final int proratedToday;

  factory SeatPack.fromJson(Map<String, dynamic> json) => SeatPack(
    seats: jsonInt(json['Seats']) ?? 1,
    pricePerMonth: jsonInt(json['PricePerMonth']) ?? 0,
    proratedToday: jsonInt(json['ProratedToday']) ?? 0,
  );
}
