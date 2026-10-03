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

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    code: json['Code'] as String? ?? '',
    inviter: LocalizedName(
      json['InviterName'] as String? ?? '',
      json['InviterNameBn'] as String? ?? '',
    ),
    creditAmount: jsonInt(json['CreditAmount']) ?? 0,
    trialDays: jsonInt(json['TrialDays']) ?? 0,
  );
}
