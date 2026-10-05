import 'package:salesroot/core/utils/json_fields.dart';

/// Who shared the sign-up link, and what registering with it gives.
class Referral {
  const Referral({
    required this.code,
    required this.inviter,
    required this.creditAmount,
    required this.trialDays,
  });

  final String code;
  final LocalizedName inviter;
  final int creditAmount;
  final int trialDays;

  /// `GET /public/referral/{code}`: `{invitedBy, company, bonus}`.
  factory Referral.fromJson(String code, Map<String, dynamic> json) {
    final bonus = jsonMap(json['bonus']);
    final inviter = json['invitedBy'] as String? ?? '';
    return Referral(
      code: code,
      inviter: LocalizedName(inviter, inviter),
      creditAmount: jsonInt(bonus['credits']) ?? 0,
      trialDays: jsonInt(bonus['trialDays']) ?? 0,
    );
  }
}
