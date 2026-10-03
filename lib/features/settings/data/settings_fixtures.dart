import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/features/settings/models/device_session.dart';

const notificationPrefsSeed = {
  'Topics': [
    'Reminders',
    'Assignments',
    'Chat',
    'NewLeads',
    'Inbox',
    'Notices',
    'Billing',
  ],
  'DigestMinute': 540,
  'QuietEnabled': true,
  'QuietFromMinute': 1320,
  'QuietToMinute': 420,
};

const _devices = [
  ('Samsung A15 · Android 14', DeviceKind.android, 'Dhaka', 0),
  ('iPhone 13', DeviceKind.ios, 'Dhaka', 2),
  ('Chrome · Windows', DeviceKind.web, 'app.salesrootcrm.com', 5),
];

List<Map<String, dynamic>> deviceFixtures(SeedGraph graph) => [
  for (var i = 0; i < _devices.length; i++)
    {
      'Id': i + 1,
      'Name': _devices[i].$1,
      'Kind': _devices[i].$2.wire,
      'Location': _devices[i].$3,
      'IsCurrent': i == 0,
      'LastActiveAt': AppDateUtils.toApiUtc(
        graph.daysAgo(_devices[i].$4, hour: 8 + i * 5, minute: 52 - i * 7),
      ),
    },
];

List<Map<String, dynamic>> loginFixtures(SeedGraph graph) {
  final random = graph.random('settings/logins');
  const devices = ['Samsung A15', 'iPhone 13', 'Chrome'];
  final rows = <Map<String, dynamic>>[];
  var day = 0;
  for (var id = 1; id <= 46; id++) {
    final device = random.nextInt(10) < 6
        ? 0
        : random.nextInt(10) < 7
        ? 1
        : 2;
    final method = switch (device) {
      0 => random.nextBool() ? LoginMethod.pin : LoginMethod.fingerprint,
      1 => LoginMethod.face,
      _ => LoginMethod.passwordOtp,
    };
    rows.add({
      'Id': id,
      'Device': devices[device],
      'Method': method.wire,
      'At': AppDateUtils.toApiUtc(
        graph.daysAgo(
          day,
          hour: 7 + random.nextInt(15),
          minute: random.nextInt(60),
        ),
      ),
    });
    day += random.nextInt(3);
  }
  return rows;
}
