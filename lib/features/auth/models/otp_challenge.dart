import 'package:salesroot/core/utils/json_fields.dart';

enum OtpChannel { sms, call }

/// A code was sent to [phone]; another may be asked for after
/// [resendAfterSeconds].
class OtpChallenge {
  const OtpChallenge({
    required this.phone,
    required this.resendAfterSeconds,
    required this.channel,
  });

  final String phone;
  final int resendAfterSeconds;
  final OtpChannel channel;

  factory OtpChallenge.fromJson(
    Map<String, dynamic> json, {
    OtpChannel channel = OtpChannel.sms,
  }) => OtpChallenge(
    phone: json['phone'] as String? ?? '',
    resendAfterSeconds: jsonInt(json['resendAfterSec']) ?? 60,
    channel: channel,
  );
}
