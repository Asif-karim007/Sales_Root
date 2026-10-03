import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/features/billing/data/billing_fixtures.dart';

const Map<String, dynamic> referralProgramJson = {
  'Code': 'KH7R2M',
  'Link': 'https://q.salesrootcrm.com/r/KH7R2M',
  'RegisterReward': 10,
  'ConversionPercent': 10,
  'ConversionCap': 500,
  'TrialDays': 15,
  'HoldHours': 48,
  'InviteDays': 90,
  'Milestones': [
    {'Paid': 1},
    {'Paid': 5, 'Reward': 500},
    {'Paid': 10, 'Reward': 1500},
    {'Paid': 25, 'FreeMonths': 1},
  ],
};

typedef _Friend = ({
  String name,
  String nameBn,
  String phone,
  String status,
  int invited,
  int? registered,
  int? bought,
  String? plan,
  int bill,
  String channel,
});

const List<_Friend> _friends = [
  (
    name: 'Rashed Khan',
    nameBn: 'রাশেদ খান',
    phone: '01715288144',
    status: 'Bought',
    invited: 40,
    registered: 34,
    bought: 1,
    plan: 'Team',
    bill: 2394,
    channel: 'WhatsApp',
  ),
  (
    name: 'Sumi Begum',
    nameBn: 'সুমি বেগম',
    phone: '01911467208',
    status: 'Registered',
    invited: 6,
    registered: 0,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Masud Traders',
    nameBn: 'মাসুদ ট্রেডার্স',
    phone: '01819226655',
    status: 'Pending',
    invited: 2,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Farhana Yasmin',
    nameBn: 'ফারহানা ইয়াসমিন',
    phone: '01611903422',
    status: 'NotEligible',
    invited: 20,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Jamal Store',
    nameBn: 'জামাল স্টোর',
    phone: '01712648890',
    status: 'Expired',
    invited: 120,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Qr',
  ),
  (
    name: 'Nipa Akter',
    nameBn: 'নিপা আক্তার',
    phone: '01511732033',
    status: 'Reversed',
    invited: 70,
    registered: 66,
    bought: 50,
    plan: 'Personal Pro',
    bill: 1990,
    channel: 'Sms',
  ),
  (
    name: 'Sajib Hossain',
    nameBn: 'সজীব হোসেন',
    phone: '01716552310',
    status: 'Registered',
    invited: 30,
    registered: 1,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'WhatsApp',
  ),
  (
    name: 'Tuhin Mia',
    nameBn: 'তুহিন মিয়া',
    phone: '01817334120',
    status: 'Bought',
    invited: 95,
    registered: 90,
    bought: 80,
    plan: 'Business',
    bill: 5990,
    channel: 'Qr',
  ),
  (
    name: 'Rezaul Karim',
    nameBn: 'রেজাউল করিম',
    phone: '01713998812',
    status: 'Bought',
    invited: 200,
    registered: 190,
    bought: 175,
    plan: 'Team',
    bill: 3990,
    channel: 'Sms',
  ),
  (
    name: 'Ayesha Siddiqua',
    nameBn: 'আয়েশা সিদ্দিকা',
    phone: '01912455610',
    status: 'Registered',
    invited: 150,
    registered: 140,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Messenger',
  ),
  (
    name: 'Rahim Agro',
    nameBn: 'রহিম এগ্রো',
    phone: '01711458822',
    status: 'Pending',
    invited: 10,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Recorded',
  ),
  (
    name: 'Kawsar Ahmed',
    nameBn: 'কাওসার আহমেদ',
    phone: '01914225566',
    status: 'Registered',
    invited: 346,
    registered: 345,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Green Agro',
    nameBn: 'গ্রিন এগ্রো',
    phone: '01819665544',
    status: 'Pending',
    invited: 45,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Lipi Khatun',
    nameBn: 'লিপি খাতুন',
    phone: '01558774411',
    status: 'Expired',
    invited: 180,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'WhatsApp',
  ),
  (
    name: 'Sohel Rana',
    nameBn: 'সোহেল রানা',
    phone: '01674332211',
    status: 'Registered',
    invited: 60,
    registered: 55,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Unity Hardware',
    nameBn: 'ইউনিটি হার্ডওয়্যার',
    phone: '01715665588',
    status: 'Pending',
    invited: 25,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Qr',
  ),
  (
    name: 'Nazmul Huda',
    nameBn: 'নাজমুল হুদা',
    phone: '01811223344',
    status: 'NotEligible',
    invited: 80,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Shapla Garments',
    nameBn: 'শাপলা গার্মেন্টস',
    phone: '01733445566',
    status: 'Pending',
    invited: 60,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Mizanur Rahman',
    nameBn: 'মিজানুর রহমান',
    phone: '01922334455',
    status: 'Registered',
    invited: 100,
    registered: 92,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'WhatsApp',
  ),
  (
    name: 'Kohinoor Akter',
    nameBn: 'কোহিনূর আক্তার',
    phone: '01633221100',
    status: 'Expired',
    invited: 200,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Star Electric',
    nameBn: 'স্টার ইলেকট্রিক',
    phone: '01755443322',
    status: 'Pending',
    invited: 4,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Recorded',
  ),
  (
    name: 'Parvez Alam',
    nameBn: 'পারভেজ আলম',
    phone: '01866554433',
    status: 'Registered',
    invited: 15,
    registered: 12,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Comilla Bakery',
    nameBn: 'কুমিল্লা বেকারি',
    phone: '01944332211',
    status: 'Expired',
    invited: 150,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Joynal Abedin',
    nameBn: 'জয়নাল আবেদিন',
    phone: '01577889900',
    status: 'Pending',
    invited: 70,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
  (
    name: 'Rokeya Sultana',
    nameBn: 'রোকেয়া সুলতানা',
    phone: '01688776655',
    status: 'NotEligible',
    invited: 33,
    registered: null,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'WhatsApp',
  ),
  (
    name: 'Abul Kalam',
    nameBn: 'আবুল কালাম',
    phone: '01799887766',
    status: 'Registered',
    invited: 210,
    registered: 205,
    bought: null,
    plan: null,
    bill: 0,
    channel: 'Sms',
  ),
];

/// The user's invites, newest first. Sumi's registration is the reward the
/// app has not celebrated yet.
List<Map<String, dynamic>> referralFixtures(SeedGraph graph) {
  final rows = [
    for (var i = 0; i < _friends.length; i++)
      _referral(graph, i + 1, _friends[i]),
  ];
  rows.sort(
    (a, b) => (b['InvitedAt'] as String).compareTo(a['InvitedAt'] as String),
  );
  return rows;
}

Map<String, dynamic> _referral(SeedGraph graph, int id, _Friend friend) {
  final registered = friend.registered;
  final bought = friend.bought;
  return {
    'Id': id,
    'Name': friend.name,
    'NameBn': friend.nameBn,
    'Phone': friend.phone,
    'Status': friend.status,
    'Channel': friend.channel,
    'InvitedAt': _at(graph.daysAgo(friend.invited, hour: 11)),
    'RegisteredAt': registered == null
        ? null
        : _at(_registeredAt(graph, registered)),
    'BoughtAt': bought == null
        ? null
        : _at(graph.daysAgo(bought, hour: 15, minute: 20)),
    'PlanName': friend.plan,
    'Bill': friend.bill,
  }..removeWhere((_, value) => value == null);
}

/// Credits and debits, consistent with [referralFixtures].
List<Map<String, dynamic>> walletFixtures(SeedGraph graph) {
  const register = 10;
  const percent = 10;
  const cap = 500;
  final rows = <Map<String, dynamic>>[
    {
      'Kind': 'Welcome',
      'Amount': 50,
      'At': _at(graph.daysAgo(340, hour: 12)),
      'Name': 'Rahim',
      'NameBn': 'রহিম',
    },
    {
      'Kind': 'Redeemed',
      'Amount': -500,
      'At': _at(graph.daysAgo(27, hour: 9, minute: 12)),
      'InvoiceNumber': creditedInvoiceNumber,
      'PlanName': 'Team',
    },
  ];
  for (var i = 0; i < _friends.length; i++) {
    final friend = _friends[i];
    final registered = friend.registered;
    if (registered == null) continue;
    final registeredAt = _registeredAt(graph, registered);
    rows.add({
      'Kind': 'Registration',
      'ReferralId': i + 1,
      'Amount': register,
      'At': _at(registeredAt),
      'AvailableAt': _at(registeredAt.add(const Duration(hours: 48))),
      'Name': friend.name,
      'NameBn': friend.nameBn,
      if (registered == 0) 'Celebrate': true,
    });
    final bought = friend.bought;
    if (bought == null) continue;
    final reward = (friend.bill * percent / 100).round().clamp(0, cap);
    rows.add({
      'Kind': 'Conversion',
      'ReferralId': i + 1,
      'Amount': reward,
      'At': _at(graph.daysAgo(bought, hour: 15, minute: 20)),
      'Name': friend.name,
      'NameBn': friend.nameBn,
      'PlanName': friend.plan,
    });
    if (friend.status == 'Reversed') {
      rows.add({
        'Kind': 'Reversed',
        'ReferralId': i + 1,
        'Amount': -reward,
        'At': _at(graph.daysAgo(35, hour: 10)),
        'Name': friend.name,
        'NameBn': friend.nameBn,
      });
    }
  }
  rows.sort((a, b) => (b['At'] as String).compareTo(a['At'] as String));
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'Id': rows.length - i},
  ];
}

/// Today's registration lands a few hours before the seed's "now".
DateTime _registeredAt(SeedGraph graph, int daysAgo) => daysAgo == 0
    ? graph.anchor.subtract(const Duration(hours: 5))
    : graph.daysAgo(daysAgo, hour: 9, minute: 30);

String _at(DateTime date) => AppDateUtils.toApiUtc(date);
