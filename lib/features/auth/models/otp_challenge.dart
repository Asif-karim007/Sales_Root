import 'package:salesroot/core/utils/json_fields.dart';

enum OtpChannel {
  sms('Sms'),
  call('Call');

  const OtpChannel(this.wire);

  final String wire;

  static OtpChannel fromWire(String? value) =>
      value == call.wire ? OtpChannel.call : OtpChannel.sms;
}

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

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
    phone: json['Phone'] as String? ?? '',
    resendAfterSeconds: jsonInt(json['ResendAfterSeconds']) ?? 60,
    channel: OtpChannel.fromWire(json['Channel'] as String?),
  );
}
