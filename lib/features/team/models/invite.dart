import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/models/member.dart';

/// A membership that has been invited but not accepted yet.
class Invite {
  const Invite({
    required this.id,
    this.name,
    this.phone,
    this.role = MemberRole.executive,
    this.managerId,
    this.managerName,
    this.level,
    this.expiresAt,
  });

  /// The invited membership's id.
  final String id;
  final String? name;
  final String? phone;
  final MemberRole role;
  final String? managerId;
  final LocalizedName? managerName;

  /// Null when the invitee picks their own level.
  final ExperienceLevel? level;
  final DateTime? expiresAt;

  /// The name, else the number the invite went to.
  String get label {
    final name = this.name;
    if (name != null && name.isNotEmpty) return name;
    return phone ?? '';
  }

  /// A `workspaces/members` row with status `invited`.
  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
    id: jsonId(json['id']) ?? jsonId(json['membershipId']) ?? '',
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    role: MemberRole.fromWire(json['role'] as String?),
    managerId: jsonId(json['reportsTo']),
    level: ExperienceLevel.fromWire(json['level'] as String?),
    expiresAt: jsonDate(json['inviteExpiresAt']),
  );

  Invite withManager(LocalizedName? managerName) => Invite(
    id: id,
    name: name,
    phone: phone,
    role: role,
    managerId: managerId,
    managerName: managerName,
    level: level,
    expiresAt: expiresAt,
  );
}

/// `InviteRequest`.
class InviteInput {
  const InviteInput({
    required this.phone,
    this.role = MemberRole.executive,
    this.managerId,
    this.level,
  });

  final String phone;
  final MemberRole role;
  final String? managerId;
  final ExperienceLevel? level;

  Map<String, dynamic> toJson() => {
    'phone': phone.trim().replaceAll(RegExp(r'[\s-]'), ''),
    'role': role.wire,
    'reportsTo': managerId,
    'level': level?.wire,
  }..removeWhere((_, value) => value == null);
}

/// Extra users the owner can add when every seat is taken.
class SeatPack {
  const SeatPack({required this.seats, required this.pricePerMonth});

  final int seats;
  final double pricePerMonth;

  /// The pack sizes the no-seat sheet offers.
  static const sizes = [1, 5, 10];

  /// The packs for [planKey], priced from `GET billing/catalogue`.
  static List<SeatPack> fromCatalogue(
    Map<String, dynamic> json,
    String planKey,
  ) {
    final plans = jsonList(json['plans'], (plan) => plan);
    final plan = plans.where((p) => p['key'] == planKey).firstOrNull;
    final perUser = jsonDouble(plan?['monthlyPerUser']);
    if (perUser == null || perUser <= 0) return const [];
    return [
      for (final seats in sizes)
        SeatPack(seats: seats, pricePerMonth: perUser * seats),
    ];
  }
}
