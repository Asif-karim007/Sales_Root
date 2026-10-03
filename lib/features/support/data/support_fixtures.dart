import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// The support agents who answer in the fake.
const supportAgents = ['Nabila', 'Tanjila'];

List<Map<String, dynamic>> ticketFixtures(SeedGraph graph) {
  final me = graph.me;
  final first = me.name.split(' ').first;
  final company = graph.companies.length > 1
      ? graph.companies[1].name
      : graph.companies.first.name;
  return [
    {
      'Id': 4,
      'Number': 'SR-1045',
      'Subject': 'bKash payment not showing in my plan',
      'Category': 'Billing',
      'Status': 'Open',
      'ReplyWithinHours': 4,
      'UpdatedAt': jsonUtc(graph.daysAgo(0, hour: 8, minute: 40)),
      'Messages': [
        _message(
          1,
          'Pro plan-er jonno bKash-e ৳ 1,499 pay korechi (TrxID 9KD7Q2M1XA), kintu app-e ekhono Free plan dekhacche.',
          graph.daysAgo(0, hour: 8, minute: 40),
          author: me.name,
          attachments: [
            {'Name': 'bkash_receipt.jpg', 'Kind': 'Image'},
          ],
        ),
      ],
    },
    {
      'Id': 3,
      'Number': 'SR-1042',
      'Subject': 'Bangla names on card scan',
      'Category': 'Bug',
      'Status': 'Replied',
      'ReplyWithinHours': 8,
      'AgentName': supportAgents.first,
      'UpdatedAt': jsonUtc(graph.daysAgo(0, hour: 9, minute: 10)),
      'Messages': [
        _message(
          1,
          'Card scan reads “Md. Karim” as “Mo Karin”. কার্ড স্ক্যানে বাংলা নাম প্রায়ই ভুল আসছে।',
          graph.daysAgo(1, hour: 16, minute: 20),
          author: me.name,
          attachments: [
            {'Name': 'scan_review.png', 'Kind': 'Image'},
          ],
        ),
        _message(
          2,
          'Thanks, $first bhai. Got the screenshot. A Bangla OCR update ships with this week’s release; until then please correct the name on the Review screen before saving. — Nabila, SalesRoot Support',
          graph.daysAgo(0, hour: 9, minute: 5),
          agent: true,
          author: supportAgents.first,
        ),
        _message(
          3,
          'ঠিক আছে, ধন্যবাদ।',
          graph.daysAgo(0, hour: 9, minute: 10),
          author: me.name,
        ),
      ],
    },
    {
      'Id': 2,
      'Number': 'SR-1038',
      'Subject': 'Quotation PDF adds VAT twice',
      'Category': 'Bug',
      'Status': 'Resolved',
      'ReplyWithinHours': 8,
      'AgentName': supportAgents.last,
      'UpdatedAt': jsonUtc(graph.daysAgo(6, hour: 15, minute: 2)),
      'Messages': [
        _message(
          1,
          '$company-er quotation PDF-e VAT duibar add hocche, total ভুল আসছে। Customer confuse hoye geche.',
          graph.daysAgo(7, hour: 11, minute: 34),
          author: me.name,
        ),
        _message(
          2,
          'Thanks for the details. We found it: VAT was added again when a discount came after it. It is fixed in today’s update — please update the app and send the quotation again. — Tanjila, SalesRoot Support',
          graph.daysAgo(6, hour: 12, minute: 15),
          agent: true,
          author: supportAgents.last,
        ),
        _message(
          3,
          'Updated, ekhon thik ache. Thanks!',
          graph.daysAgo(6, hour: 15, minute: 2),
          author: me.name,
        ),
      ],
    },
    {
      'Id': 1,
      'Number': 'SR-1031',
      'Subject': 'Moving leads when a member leaves',
      'Category': 'Question',
      'Status': 'Resolved',
      'ReplyWithinHours': 8,
      'AgentName': supportAgents.first,
      'UpdatedAt': jsonUtc(graph.daysAgo(14, hour: 17, minute: 45)),
      'Messages': [
        _message(
          1,
          'Amader ekjon member chakri chere dicche. Tar leads ar tasks onno karo kache kivabe dibo?',
          graph.daysAgo(15, hour: 10, minute: 12),
          author: me.name,
        ),
        _message(
          2,
          'Open Team → the member → Remove. Before removing, the app asks who should get their open leads, tasks and visits; pick a teammate and everything moves together. The history stays on each lead. — Nabila, SalesRoot Support',
          graph.daysAgo(15, hour: 14, minute: 30),
          agent: true,
          author: supportAgents.first,
        ),
        _message(
          3,
          'Perfect, done. ধন্যবাদ!',
          graph.daysAgo(14, hour: 17, minute: 45),
          author: me.name,
        ),
      ],
    },
  ];
}

Map<String, dynamic> _message(
  int id,
  String body,
  DateTime sentAt, {
  required String author,
  bool agent = false,
  List<Map<String, dynamic>> attachments = const [],
}) => {
  'Id': id,
  'Body': body,
  'FromAgent': agent,
  'AuthorName': author,
  'SentAt': jsonUtc(sentAt),
  'Attachments': attachments,
};

/// What the fake agent answers to [text]: in Bangla when the user wrote in
/// Bangla, matched on a few topics.
String agentReply({
  required String text,
  required String category,
  required String firstName,
  required String agent,
  required bool bangla,
  required bool followUp,
}) {
  final lower = text.toLowerCase();
  bool mentions(List<String> words) => words.any(lower.contains);
  final sign = bangla
      ? '— $agent, SalesRoot সাপোর্ট'
      : '— $agent, SalesRoot Support';

  if (followUp && mentions(['still', 'again', 'এখনো', 'আবার', 'same'])) {
    return bangla
        ? 'দুঃখিত, সমস্যাটা এখনো আছে। আমি এটি আমাদের ইঞ্জিনিয়ারদের কাছে পাঠিয়েছি; আজকের মধ্যে আপডেট জানাব। ততক্ষণ অ্যাপটি একবার বন্ধ করে আবার খুলে দেখুন। $sign'
        : 'Sorry it is still happening. I have escalated it to our engineers and will update you here today. Meanwhile, please close and reopen the app once. $sign';
  }
  if (mentions(['scan', 'card', 'ocr', 'স্ক্যান', 'কার্ড'])) {
    return bangla
        ? 'ধন্যবাদ, $firstName। স্ক্রিনশট পেয়েছি। বাংলা নাম পড়ার উন্নতি এ সপ্তাহের আপডেটে আসছে; ততক্ষণ “মিলিয়ে দেখুন” স্ক্রিনে নামটি ঠিক করে সেভ করুন। $sign'
        : 'Thanks, $firstName. Got it. Better Bangla name reading ships with this week’s update; until then please correct the name on the Review screen before saving. $sign';
  }
  if (category == 'Billing' ||
      mentions([
        'bkash',
        'nagad',
        'pay',
        'bill',
        'plan',
        'বিকাশ',
        'পেমেন্ট',
        'টাকা',
      ])) {
    return bangla
        ? 'ধন্যবাদ, $firstName। আপনার পেমেন্টটি মিলিয়ে দেখেছি এবং প্ল্যান চালু করে দিয়েছি। অ্যাপে পুরোনো প্ল্যান দেখালে একবার নিচে টেনে রিফ্রেশ করুন। $sign'
        : 'Thanks, $firstName. I matched your payment and activated the plan. If the app still shows the old plan, pull down to refresh once. $sign';
  }
  if (category == 'Suggestion') {
    return bangla
        ? 'চমৎকার পরামর্শ, $firstName! আমাদের প্রোডাক্ট টিমের তালিকায় যোগ করেছি। এটি তৈরি হলে আপনাকে এখানেই জানাব। $sign'
        : 'Great suggestion, $firstName! I have added it to our product team’s list and will tell you here when it ships. $sign';
  }
  return bangla
      ? 'ধন্যবাদ, $firstName। আপনার বার্তা পেয়েছি এবং দেখছি। স্ক্রিনশট ও ফোনের তথ্যসহ টিমকে জানিয়েছি; এক কর্মদিবসের মধ্যে এখানে উত্তর দেব। $sign'
      : 'Thanks, $firstName. We have your message and are looking into it. I have shared it with the team along with your screenshot and phone details, and will reply here within one business day. $sign';
}
