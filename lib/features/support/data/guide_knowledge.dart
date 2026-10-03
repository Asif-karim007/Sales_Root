import 'package:salesroot/features/support/models/app_destination.dart';

/// A curated answer about how SalesRoot works, beyond the help articles.
class GuideTopic {
  const GuideTopic({
    required this.keywords,
    required this.en,
    required this.bn,
    this.actions = const [],
  });

  final List<String> keywords;
  final String en;
  final String bn;
  final List<AppDestination> actions;
}

const guideTopics = [
  GuideTopic(
    keywords: [
      'stage',
      'stages',
      'pipeline',
      'interested',
      'ধাপ',
      'আগ্রহী',
      'পাইপলাইন',
    ],
    en: 'Leads move through six stages: To contact → Contacted → Interested → Quotation → Won or Lost. “Interested” means the customer asked for a price or samples. The next stage is “Quotation”; the button below starts one.',
    bn: 'লিড ছয়টি ধাপে এগোয়: যোগাযোগ বাকি → যোগাযোগ হয়েছে → আগ্রহী → কোটেশন → জিতেছি বা হারিয়েছি। “আগ্রহী” মানে গ্রাহক দাম বা স্যাম্পল চেয়েছেন। পরের ধাপ “কোটেশন”; নিচের বোতাম চাপলেই কোটেশন বানানো শুরু হবে।',
    actions: [AppDestination.newQuotation],
  ),
  GuideTopic(
    keywords: [
      'who are you',
      'what can you do',
      'what can you',
      'guide',
      'তুমি কে',
      'আপনি কে',
      'কী করতে পারো',
      'কী করতে পারেন',
    ],
    en: 'I am the SalesRoot guide. Ask me how to do anything in the app — add a lead, scan a card, send a quotation, record a collection, invite a member — and I will show you the steps and take you to the right screen. I never create or send anything without asking you first.',
    bn: 'আমি SalesRoot গাইড। অ্যাপে যেকোনো কাজ কীভাবে করবেন জিজ্ঞেস করুন — লিড যোগ, কার্ড স্ক্যান, কোটেশন পাঠানো, কালেকশন লেখা, সদস্য আমন্ত্রণ — আমি ধাপগুলো দেখিয়ে সঠিক স্ক্রিনে নিয়ে যাব। আপনাকে না জিজ্ঞেস করে কিছুই বানাই বা পাঠাই না।',
    actions: [AppDestination.help],
  ),
  GuideTopic(
    keywords: [
      'learn',
      'training',
      'course',
      'academy',
      'lesson',
      'sell better',
      'sales tips',
      'শিখ',
      'প্রশিক্ষণ',
      'একাডেমি',
      'পাঠ',
      'টিপস',
    ],
    en: 'The Sales Academy has short lessons in Bangla with English subtitles — cold calling, closing, follow-up and a career path from sales executive to team lead. Most take 2–4 minutes and end with one quick question.',
    bn: 'সেলস একাডেমিতে বাংলায় ছোট ছোট পাঠ আছে, ইংরেজি সাবটাইটেলসহ — কোল্ড কল, ক্লোজিং, ফলো-আপ, আর সেলস এক্সিকিউটিভ থেকে টিম লিড হওয়ার ক্যারিয়ার পথ। বেশিরভাগ পাঠ ২–৪ মিনিটের, শেষে একটা ছোট প্রশ্ন।',
    actions: [AppDestination.academy],
  ),
  GuideTopic(
    keywords: [
      'human',
      'agent',
      'talk to support',
      'contact support',
      'complain',
      'complaint',
      'bug',
      'not working',
      'সাপোর্ট',
      'অভিযোগ',
      'কাজ করছে না',
      'সমস্যা',
    ],
    en: 'Sorry about the trouble. Send a support request with a screenshot and our team replies within 8 hours, Sunday to Thursday. You can also call 09611-000000 between 9:00 and 18:00.',
    bn: 'ঝামেলার জন্য দুঃখিত। স্ক্রিনশটসহ সাপোর্টের অনুরোধ পাঠান, রবি থেকে বৃহস্পতিবার আমাদের টিম ৮ ঘণ্টার মধ্যে উত্তর দেয়। ৯:০০ থেকে ১৮:০০-এর মধ্যে ০৯৬১১-০০০০০০ নম্বরে কলও করতে পারেন।',
    actions: [AppDestination.support],
  ),
  GuideTopic(
    keywords: [
      'easy mode',
      'simple',
      'too many buttons',
      'confusing',
      'experience level',
      'সহজ',
      'জটিল',
      'অনেক বোতাম',
    ],
    en: 'You can make the app simpler. Switch to the Easy level in Settings → Language and level: bigger buttons, shorter forms and only the main tabs. You can move to Standard any time.',
    bn: 'অ্যাপ আরও সহজ করা যায়। সেটিংস → ভাষা ও লেভেল থেকে Easy লেভেল বেছে নিন: বড় বোতাম, ছোট ফর্ম আর শুধু মূল ট্যাব। যেকোনো সময় Standard-এ ফিরতে পারবেন।',
    actions: [AppDestination.language],
  ),
];

const guideThanks = ['thanks', 'thank you', 'thx', 'ধন্যবাদ', 'থ্যাংক'];
