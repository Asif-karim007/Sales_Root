import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

const growthCampaignsTable = 'growth_campaigns';
const growthBalanceTable = 'growth_balance';
const growthSmsTemplatesTable = 'growth_sms_templates';

const creditPackFixtures = [
  {'Id': 1, 'Credits': 1000, 'Price': 350},
  {'Id': 2, 'Credits': 5000, 'Price': 1600, 'Popular': true},
  {'Id': 3, 'Credits': 20000, 'Price': 5800},
];

List<Map<String, dynamic>> balanceFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'SmsCredits': switch (graph.workspaceId) {
      300 => 5200,
      200 => 1240,
      _ => 0,
    },
    'SmsUsedThisMonth': 2360,
    'AverageSegments': 1.8,
    'SenderId': 'SalesRoot',
    'EmailUsed': 3100,
    'EmailLimit': 10000,
    'FromEmail': 'sales@dhakasales.com',
  },
];

List<Map<String, dynamic>> smsTemplateFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'Name': 'Collection reminder',
    'NameBn': 'কালেকশন রিমাইন্ডার',
    'Body':
        'Dear {{name}}, Tk {{due}} is outstanding on {{bill}}. Pay via bKash 01711-000000 or at our office. Thank you - Dhaka Sales',
    'BodyBn':
        'প্রিয় {{name}}, আপনার {{bill}} বাবদ ৳ {{due}} বাকি আছে। bKash 01711-000000 বা অফিসে দিতে পারেন। ধন্যবাদ – Dhaka Sales',
  },
  {
    'Id': 2,
    'Name': 'Eid offer',
    'NameBn': 'ঈদ অফার',
    'Body':
        'Eid Mubarak {{name}}! 10% off rooftop solar till {{date}}. Reply YES for a free site survey. - Dhaka Sales',
    'BodyBn':
        'ঈদ মোবারক {{name}}! {{date}} পর্যন্ত রুফটপ সোলারে ১০% ছাড়। ফ্রি সাইট সার্ভের জন্য YES লিখে উত্তর দিন। – Dhaka Sales',
  },
  {
    'Id': 3,
    'Name': 'Free site survey',
    'NameBn': 'ফ্রি সাইট সার্ভে',
    'Body':
        'Hello {{name}}, cut your electricity bill with solar. Book a free site survey: reply YES or call 01711-000000.',
    'BodyBn':
        'হ্যালো {{name}}, সোলারে বিদ্যুৎ বিল কমান। ফ্রি সাইট সার্ভে বুক করতে YES লিখুন বা 01711-000000 এ কল করুন।',
  },
  {
    'Id': 4,
    'Name': 'Payment thanks',
    'NameBn': 'পেমেন্টের ধন্যবাদ',
    'Body':
        'Thank you {{name}}, we received your payment for {{bill}}. - Dhaka Sales',
    'BodyBn': 'ধন্যবাদ {{name}}, {{bill}} এর পেমেন্ট পেয়েছি। – Dhaka Sales',
  },
];

List<Map<String, dynamic>> campaignFixtures(SeedGraph graph) {
  String day(int ago, {int hour = 10}) =>
      jsonUtc(graph.daysAgo(ago, hour: hour)) ?? '';
  List<Map<String, dynamic>> replies(List<(String, bool)> texts, String salt) {
    final leads = graph.leads;
    if (leads.isEmpty) return const [];
    final random = graph.random(salt);
    return [
      for (final (text, task) in texts)
        _reply(graph, leads[random.nextInt(leads.length)], text, task),
    ];
  }

  Map<String, dynamic> sms(
    int id,
    String name,
    String segment,
    int ago,
    int sent, {
    required String message,
    int replies = 0,
    int leads = 0,
    List<int> byHour = const [],
    List<Map<String, dynamic>> replyLeads = const [],
  }) {
    final wrong = (sent * 0.026).round();
    final off = (sent * 0.014).round();
    return {
      'Id': id,
      'Name': name,
      'Channel': 'SMS',
      'Status': 'Done',
      'Segment': segment,
      'Recipients': sent,
      'Message': message,
      'SentAt': day(ago),
      'Sent': sent,
      'Delivered': sent - wrong - off,
      'WrongNumber': wrong,
      'SwitchedOff': off,
      'Replies': replies,
      'LeadsCreated': leads,
      'CreditsUsed': sent * 2,
      'RepliesByHour': byHour,
      'ReplyLeads': replyLeads,
    };
  }

  Map<String, dynamic> email(
    int id,
    String name,
    String subject,
    int ago,
    int sent, {
    required double opened,
    int leads = 0,
    List<int> byHour = const [],
  }) => {
    'Id': id,
    'Name': name,
    'Channel': 'Email',
    'Status': 'Done',
    'Segment': 'Dealers',
    'Recipients': sent,
    'Subject': subject,
    'SentAt': day(ago, hour: 11),
    'Sent': sent,
    'Delivered': sent - 4,
    'Opened': (sent * opened).round(),
    'Clicked': (sent * opened * 0.28).round(),
    'LeadsCreated': leads,
    'RepliesByHour': byHour,
  };

  return [
    {
      'Id': 3,
      'Name': 'Collection reminder',
      'Channel': 'SMS',
      'Status': 'Scheduled',
      'Segment': 'OverdueCustomers',
      'Recipients': 19,
      'Message':
          'প্রিয় {{name}}, আপনার {{bill}} বাবদ ৳ {{due}} বাকি আছে। bKash 01711-000000 বা অফিসে দিতে পারেন। ধন্যবাদ – Dhaka Sales',
      'ScheduledAt': jsonUtc(graph.daysAhead(1)),
      'CreditsUsed': 38,
    },
    {
      'Id': 11,
      'Name': 'Dealer meet invitation',
      'Channel': 'Email',
      'Status': 'Scheduled',
      'Segment': 'Dealers',
      'Recipients': 340,
      'Subject': 'Dealer meet 2026 – Radisson Blu, 12 November',
      'ScheduledAt': jsonUtc(graph.daysAhead(5, hour: 9)),
    },
    sms(
      12,
      'Free site survey – interested leads',
      'InterestedLeads',
      2,
      64,
      message:
          'Hello {{name}}, cut your electricity bill with solar. Book a free site survey: reply YES or call 01711-000000.',
      replies: 9,
      leads: 4,
      byHour: [2, 3, 1, 1, 1, 0, 1, 0],
      replyLeads: replies([
        ('YES, Saturday please', false),
        ('কত খরচ পড়বে?', true),
      ], 'campaign12'),
    ),
    sms(
      9,
      'Hot leads follow-up',
      'HotLeads',
      5,
      41,
      message:
          'Hello {{name}}, our October solar prices end this week. Reply YES and we will call you today.',
      replies: 7,
      leads: 2,
      byHour: [1, 2, 2, 1, 0, 1, 0, 0],
    ),
    {
      ...sms(
        7,
        'Winter battery check',
        'Customers',
        10,
        0,
        message: 'Free battery health check this winter. Reply YES to book.',
      ),
      'Status': 'Cancelled',
      'Recipients': 210,
    },
    sms(
      1,
      'Eid offer',
      'Customers',
      14,
      1200,
      message:
          'ঈদ মোবারক {{name}}! ১৫ অক্টোবর পর্যন্ত রুফটপ সোলারে ১০% ছাড়। ফ্রি সাইট সার্ভের জন্য YES লিখে উত্তর দিন। – Dhaka Sales',
      replies: 38,
      leads: 12,
      byHour: [3, 7, 12, 8, 4, 2, 1, 1],
      replyLeads: replies([
        ('অফারটা কী?', false),
        ('Call me', true),
        ('YES', false),
        ('3kW system er dam koto?', false),
        ('Kal office e ashbo', true),
        ('আমার দোকানের জন্য লাগবে', false),
      ], 'campaign1'),
    ),
    email(
      8,
      'New 550W panel launch',
      'Introducing the 550W mono panel – dealer price inside',
      20,
      336,
      opened: 0.58,
      leads: 5,
      byHour: [14, 31, 22, 12, 9, 6, 4, 2],
    ),
    email(
      2,
      'October price list',
      'October price list and Eid offer',
      24,
      340,
      opened: 0.62,
      leads: 6,
      byHour: [18, 40, 25, 15, 9, 8, 5, 3],
    ),
    sms(
      4,
      'Puja offer',
      'Customers',
      30,
      860,
      message:
          'শুভ পূজা {{name}}! IPS ও ব্যাটারিতে বিশেষ ছাড়, ২০ অক্টোবর পর্যন্ত। – Dhaka Sales',
      replies: 21,
      leads: 7,
      byHour: [2, 5, 6, 4, 2, 1, 1, 0],
    ),
    email(
      5,
      'Net metering webinar',
      'Free webinar: net metering for factories',
      45,
      512,
      opened: 0.41,
      leads: 9,
      byHour: [20, 35, 18, 10, 8, 5, 2, 1],
    ),
    sms(
      6,
      'Panel cleaning reminder',
      'Customers',
      60,
      420,
      message:
          'Dear {{name}}, dusty panels lose up to 25% power. Book a cleaning for Tk 3,000: call 01711-000000.',
      replies: 16,
      leads: 3,
      byHour: [1, 4, 5, 3, 1, 1, 1, 0],
    ),
    sms(
      10,
      'Eid greetings',
      'Customers',
      120,
      1100,
      message: 'ঈদ মোবারক! Dhaka Sales পরিবারের পক্ষ থেকে শুভেচ্ছা।',
      replies: 12,
      byHour: [4, 3, 2, 1, 1, 0, 1, 0],
    ),
  ];
}

Map<String, dynamic> _reply(
  SeedGraph graph,
  SeedLead lead,
  String text,
  bool task,
) => {
  'Name': graph.contact(lead.contactId).name,
  'Text': text,
  'Outcome': task ? 'Task' : 'Lead',
  'LeadId': lead.id,
};
