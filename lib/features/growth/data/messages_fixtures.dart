import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

const growthThreadsTable = 'growth_threads';
const growthMessagesTable = 'growth_messages';
const growthTemplatesTable = 'growth_templates';

/// What a customer sends back when the team writes to them.
const customerReplies = [
  'ঠিক আছে, ধন্যবাদ।',
  'Okay bhai, I will check and confirm by evening.',
  'দামটা একটু কম হবে না?',
  'Kal shokale ekbar call diyen.',
  'Received, thanks!',
  'ইনস্টলেশন কত দিনে হবে?',
  'Ami office e asi, 4 tar por ashte paren.',
  'বিকাশে পাঠালে চলবে?',
];

/// Customer, team, customer: the last line is the thread's last message.
const _conversations = [
  [
    'Inverter er warranty koto bochor?',
    'Hybrid inverter-এ ৫ বছর, ব্যাটারিতে ৩ বছর ওয়ারেন্টি।',
    'আচ্ছা, তাহলে 5kW টাই নেব।',
  ],
  [
    'Site survey kobe korte parben?',
    'Shonibar 11 tay amader engineer ashbe, thik ache?',
    'Okay, Saturday works.',
  ],
  [
    'আগের কোটেশনে ক্যাবল ধরা ছিল?',
    'Ji, 4mm² DC cable 60 metre included.',
    'ঠিক আছে, পিও পাঠাচ্ছি।',
  ],
  [
    'Panel cleaning er charge koto?',
    'প্রতি ভিজিট ৳ ৩,০০০, বছরে ৪ বার নিলে ১০% ছাড়।',
    'চার বারের প্যাকেজটাই দিন।',
  ],
  [
    'Battery backup kom hoye geche.',
    'Amader technician kal 10 tar moddhe check korbe.',
    'Thank you, please come early.',
  ],
  [
    'নেট মিটারিং এর কাগজ কি আপনারা করে দেন?',
    'Ji, DESCO te application amra kore dei, ৳ 15,000.',
    'ঠিক আছে, ডকুমেন্ট লিস্ট পাঠান।',
  ],
  [
    'Street light 60W stock e ache?',
    'Ji, 40 pcs ready stock. Delivery 2 diner moddhe.',
    'Need 25, send the bill please.',
  ],
  [
    'LC open hoyeche, delivery schedule janaben.',
    'Next Tuesday first lot, 120 panels.',
    'ধন্যবাদ, গেটে নাম দিয়ে রাখব।',
  ],
];

List<Map<String, dynamic>> threadFixtures(SeedGraph graph) {
  final members = graph.members;
  int at(int index) => members[index % members.length].id;
  final rahim = graph.company(4);
  final karim = graph.company(1);
  final city = graph.company(10);
  final rows = <Map<String, dynamic>>[
    {
      'Id': 1,
      'Channel': 'WhatsApp',
      'Name': rahim.name,
      'Phone': rahim.phone,
      'Kind': 'Customer',
      'CompanyId': rahim.id,
      'LeadId': _leadOf(graph, rahim.id),
      'Unread': 3,
      'AssignedToId': SeedGraph.meId,
      'Reference': 'SO-088',
      'DueAmount': 50000,
      'SuggestedReply':
          'বিল পাঠালাম রহিম ভাই। ২য় কিস্তি ৳ ৫০,০০০ ডেলিভারির দিন দিলে ভালো হয়।',
    },
    {
      'Id': 2,
      'Channel': 'Messenger',
      'Name': 'Nila Sikder',
      'Phone': '+8801819224466',
      'Kind': 'Lead',
      'Unread': 1,
    },
    {
      'Id': 3,
      'Channel': 'WhatsApp',
      'Name': karim.name,
      'Phone': karim.phone,
      'Kind': 'Customer',
      'CompanyId': karim.id,
      'LeadId': _leadOf(graph, karim.id),
      'AssignedToId': SeedGraph.meId,
      'Reference': 'QT-1042',
    },
    {
      'Id': 4,
      'Channel': 'WhatsApp',
      'Name': city.name,
      'Phone': city.phone,
      'Kind': 'Customer',
      'CompanyId': city.id,
      'LeadId': _leadOf(graph, city.id),
      'AssignedToId': at(3),
      'Reference': 'INV-109',
      'DueAmount': 32000,
    },
    {
      'Id': 5,
      'Channel': 'WhatsApp',
      'Name': '+8801611444555',
      'Phone': '+8801611444555',
      'Kind': 'Unknown',
    },
  ];
  const picks = [2, 3, 5, 7, 11, 13, 14, 15, 19, 20, 22, 26, 28, 33];
  const channels = ['WhatsApp', 'WhatsApp', 'SMS', 'Messenger'];
  for (var i = 0; i < picks.length; i++) {
    final company = graph.company(picks[i]);
    final contact = graph.contactsOf(company.id).first;
    rows.add({
      'Id': rows.length + 1,
      'Channel': channels[i % channels.length],
      'Name': company.name,
      'Phone': contact.phone,
      'Kind': i % 3 == 0 ? 'Customer' : 'Lead',
      'CompanyId': company.id,
      'LeadId': _leadOf(graph, company.id),
      'Unread': i % 4 == 0 ? 1 + i % 3 : 0,
      'AssignedToId': i % 5 == 4 ? null : at(i),
    });
  }
  return rows;
}

List<Map<String, dynamic>> messageFixtures(SeedGraph graph) {
  String at(int minutesAgo) =>
      jsonUtc(graph.anchor.subtract(Duration(minutes: minutesAgo))) ?? '';
  var id = 0;
  Map<String, dynamic> message(
    int threadId,
    String text,
    bool mine,
    int minutesAgo, {
    Map<String, dynamic>? attachment,
  }) => {
    'Id': ++id,
    'ThreadId': threadId,
    'Text': text,
    'Mine': mine,
    'At': at(minutesAgo),
    'Status': mine ? 'Read' : 'Delivered',
    'Attachment': attachment,
  };

  final rows = <Map<String, dynamic>>[
    message(1, 'ডেলিভারি কবে হবে?', false, 9),
    message(
      1,
      'আসসালামু আলাইকুম রহিম ভাই। আপনার অর্ডার SO-088 কাল দুপুরের মধ্যে পৌঁছাবে। ড্রাইভার আগে ফোন করবে।',
      true,
      6,
    ),
    message(1, 'ঠিক আছে। বিলটা পাঠান।', false, 5),
    message(
      1,
      '',
      true,
      4,
      attachment: {'Kind': 'Invoice', 'Name': 'INV-117', 'Amount': 100000},
    ),
    message(1, 'Driver er number ta diben?', false, 2),
    message(2, 'Hi, solar er dam janate chai', false, 25),
    message(2, 'দাম জানতে চাই — 3kW hybrid system', false, 18),
    message(3, 'Please send the revised quotation.', false, 90),
    message(
      3,
      '',
      true,
      75,
      attachment: {'Kind': 'Quotation', 'Name': 'QT-1042', 'Amount': 425000},
    ),
    message(3, 'কোটেশন পেয়েছি, ধন্যবাদ', false, 62),
    message(4, 'Bill INV-109 er due koto?', false, 220),
    message(4, '৳ ৩২,০০০ বাকি আছে ভাই।', true, 200),
    message(4, 'টাকা সোমবার দেব', false, 185),
    message(5, 'Hello', false, 300),
  ];
  const minutes = [
    34,
    52,
    140,
    260,
    410,
    600,
    1800,
    2900,
    95,
    75,
    1250,
    3300,
    4400,
    5200,
  ];
  for (var i = 0; i < minutes.length; i++) {
    final lines = _conversations[i % _conversations.length];
    final last = minutes[i];
    rows
      ..add(message(6 + i, lines[0], false, last + 40))
      ..add(message(6 + i, lines[1], true, last + 25))
      ..add(message(6 + i, lines[2], false, last));
  }
  return rows;
}

List<Map<String, dynamic>> templateFixtures(SeedGraph graph) => [
  {
    'Id': 1,
    'Name': 'Order on the way',
    'NameBn': 'অর্ডার রওনা হয়েছে',
    'Body':
        'Assalamu alaikum {{name}}, your order is on the way. The driver will call before delivery. – Dhaka Sales',
    'BodyBn':
        'আসসালামু আলাইকুম {{name}}, আপনার অর্ডার রওনা হয়েছে। ডেলিভারির আগে ড্রাইভার ফোন করবেন। – Dhaka Sales',
    'Approved': true,
  },
  {
    'Id': 2,
    'Name': 'Payment reminder',
    'NameBn': 'পেমেন্ট রিমাইন্ডার',
    'Body':
        'Dear {{name}}, a gentle reminder about your outstanding bill. Pay by bKash 01711-000000 or at our office. Thank you.',
    'BodyBn':
        'প্রিয় {{name}}, আপনার বকেয়া বিলের কথা মনে করিয়ে দিচ্ছি। bKash 01711-000000 বা অফিসে দিতে পারেন। ধন্যবাদ।',
    'Approved': true,
  },
  {
    'Id': 3,
    'Name': 'Quotation follow-up',
    'NameBn': 'কোটেশনের ফলো-আপ',
    'Body':
        'Hello {{name}}, did you get a chance to look at our quotation? Happy to answer any questions.',
    'BodyBn':
        'হ্যালো {{name}}, আমাদের কোটেশনটা দেখেছেন? কোনো প্রশ্ন থাকলে জানাবেন।',
    'Approved': true,
  },
  {
    'Id': 4,
    'Name': 'Site visit confirmation',
    'NameBn': 'সাইট ভিজিট নিশ্চিতকরণ',
    'Body':
        'Hello {{name}}, our engineer will visit your site tomorrow at 11 am for the solar survey.',
    'BodyBn':
        'হ্যালো {{name}}, আগামীকাল সকাল ১১টায় আমাদের ইঞ্জিনিয়ার সোলার সার্ভের জন্য আপনার সাইটে যাবেন।',
    'Approved': true,
  },
  {
    'Id': 5,
    'Name': 'Noted',
    'NameBn': 'নোট করলাম',
    'Body': 'Thank you, noted.',
    'BodyBn': 'ধন্যবাদ, নোট করলাম।',
  },
  {
    'Id': 6,
    'Name': 'Calling soon',
    'NameBn': 'কল করছি',
    'Body': 'I will call you in 10 minutes.',
    'BodyBn': '১০ মিনিটের মধ্যে কল করছি।',
  },
  {
    'Id': 7,
    'Name': 'Location',
    'NameBn': 'লোকেশন',
    'Body': 'Please share your location so we can plan the visit.',
    'BodyBn': 'ভিজিটের জন্য লোকেশনটা শেয়ার করবেন প্লিজ।',
  },
  {
    'Id': 8,
    'Name': 'Office hours',
    'NameBn': 'অফিসের সময়',
    'Body': 'Our office is open 9 am to 6 pm, Saturday to Thursday.',
    'BodyBn': 'আমাদের অফিস শনি থেকে বৃহস্পতি সকাল ৯টা থেকে সন্ধ্যা ৬টা খোলা।',
  },
];

int? _leadOf(SeedGraph graph, int companyId) =>
    graph.leads.where((l) => l.companyId == companyId).firstOrNull?.id;
