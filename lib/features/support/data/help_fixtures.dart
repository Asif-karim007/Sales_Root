import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

const _videoBase = 'https://salesroot.com.bd/help/videos';

List<Map<String, dynamic>> helpFixtures(SeedGraph graph) {
  final random = graph.random('help');
  return [
    for (final (i, article) in _articles.indexed)
      {
        ...article,
        'Id': i + 1,
        'HelpfulCount': 12 + random.nextInt(240),
        'UpdatedAt': jsonUtc(graph.daysAgo(3 + random.nextInt(80))),
      },
  ];
}

Map<String, dynamic> _article({
  required String category,
  required (String, String) title,
  required (String, String) summary,
  required List<(String, String)> steps,
  required List<String> keywords,
  (String, String)? tip,
  String? action,
  int readMinutes = 2,
  int? videoSeconds,
  String? video,
  bool popular = false,
}) => {
  'Category': category,
  'Title': title.$1,
  'TitleBn': title.$2,
  'Summary': summary.$1,
  'SummaryBn': summary.$2,
  'Steps': [
    for (final step in steps) {'Text': step.$1, 'TextBn': step.$2},
  ],
  'Tip': ?tip?.$1,
  'TipBn': ?tip?.$2,
  'ReadMinutes': readMinutes,
  'VideoSeconds': ?videoSeconds,
  if (video != null) 'VideoUrl': '$_videoBase/$video',
  'Popular': popular,
  'Action': ?action,
  'Keywords': keywords,
};

final List<Map<String, dynamic>> _articles = [
  _article(
    category: 'Leads',
    popular: true,
    action: 'ScanCard',
    videoSeconds: 70,
    video: 'scan-card',
    title: ('How do I scan a visiting card?', 'কার্ড স্ক্যান কীভাবে করব?'),
    summary: (
      'Turn a visiting card into a contact and a lead without typing.',
      'টাইপ না করেই ভিজিটিং কার্ড থেকে কনট্যাক্ট ও লিড বানান।',
    ),
    steps: [
      ('Tap the camera icon on Home.', 'হোমে ক্যামেরা আইকন চাপুন।'),
      (
        'Hold the card inside the frame in good light.',
        'কার্ডটি ফ্রেমের ভেতরে রাখুন; আলো থাকলে ভালো।',
      ),
      (
        'Check the parsed fields and fix any mistakes.',
        'পড়া তথ্য মিলিয়ে দেখুন, ভুল ঘর ঠিক করুন।',
      ),
      (
        'Tap “Create lead” to save both a contact and a lead.',
        '“লিড বানান” চাপলে কনট্যাক্ট ও লিড দুটোই তৈরি হবে।',
      ),
    ],
    tip: (
      'Free plan: 5 scans a month; Pro: 100.',
      'ফ্রি প্ল্যানে মাসে ৫টি স্ক্যান; Pro-তে ১০০।',
    ),
    keywords: [
      'scan',
      'card',
      'visiting card',
      'business card',
      'camera',
      'ocr',
      'স্ক্যান',
      'কার্ড',
      'ভিজিটিং',
      'ক্যামেরা',
    ],
  ),
  _article(
    category: 'Team',
    popular: true,
    action: 'InviteMember',
    title: ('How do I add a member to my team?', 'টিমে সদস্য যোগ করব কীভাবে?'),
    summary: (
      'Invite a salesperson by mobile number; they join with their own login.',
      'মোবাইল নম্বর দিয়ে সেলসপার্সনকে আমন্ত্রণ জানান; তিনি নিজের লগইনে যোগ দেবেন।',
    ),
    steps: [
      (
        'Open More → Team and tap “Invite”.',
        'আরও → টিম খুলে “আমন্ত্রণ” চাপুন।',
      ),
      (
        'Enter their name and mobile number, then choose a role: Member, Team lead or Owner.',
        'নাম ও মোবাইল নম্বর দিন, তারপর ভূমিকা বেছে নিন: সদস্য, টিম লিড বা মালিক।',
      ),
      (
        'Pick who they report to, so their leads show up for the right team lead.',
        'কার কাছে রিপোর্ট করবেন তা বেছে নিন, যাতে তাঁর লিড সঠিক টিম লিডের কাছে দেখা যায়।',
      ),
      (
        'Send. They get an SMS with a link; once they set a PIN they appear in your team.',
        'পাঠান। তিনি লিংকসহ SMS পাবেন; PIN সেট করলেই আপনার টিমে দেখা যাবে।',
      ),
    ],
    tip: (
      'Each member uses one seat in your plan. Removing a member frees the seat; the leads they made stay with the team.',
      'প্রতিটি সদস্য প্ল্যানের একটি সিট নেন। সদস্য সরালে সিট খালি হয়; তাঁর বানানো লিড টিমেই থাকে।',
    ),
    keywords: [
      'member',
      'invite',
      'add member',
      'salesperson',
      'staff',
      'employee',
      'seat',
      'সদস্য',
      'সদস্য যোগ',
      'আমন্ত্রণ',
      'কর্মী',
      'স্টাফ',
    ],
  ),
  _article(
    category: 'Account',
    popular: true,
    action: 'OfflineSync',
    readMinutes: 3,
    title: ('What happens when I work offline?', 'নেট ছাড়া কাজ করলে কী হয়?'),
    summary: (
      'Keep working without internet; the app sends everything when you are back online.',
      'ইন্টারনেট ছাড়াও কাজ চালিয়ে যান; নেট ফিরলে অ্যাপ সব পাঠিয়ে দেবে।',
    ),
    steps: [
      (
        'Leads, contacts, tasks and visits from the last 90 days stay on your phone, so you can open them anywhere.',
        'গত ৯০ দিনের লিড, কনট্যাক্ট, কাজ ও ভিজিট ফোনেই থাকে, তাই যেকোনো জায়গায় খুলতে পারবেন।',
      ),
      (
        'Anything you add or edit offline is queued. A small cloud icon shows how many changes are waiting.',
        'নেট ছাড়া যা যোগ বা বদল করবেন তা লাইনে থাকে। ছোট মেঘের আইকনে দেখায় কয়টি পরিবর্তন অপেক্ষায় আছে।',
      ),
      (
        'When the connection returns, the queue is sent in order. Open More → Sync to see what went through.',
        'সংযোগ ফিরলে পরিবর্তনগুলো ক্রমানুসারে চলে যায়। কী গেল তা দেখতে আরও → সিঙ্ক খুলুন।',
      ),
      (
        'If someone else changed the same record, you choose which value to keep, field by field.',
        'অন্য কেউ একই রেকর্ড বদলে থাকলে কোন তথ্য রাখবেন, ঘর ধরে ধরে আপনি বেছে নেবেন।',
      ),
    ],
    tip: (
      'Photos and files upload on Wi-Fi only, unless you change it in Settings.',
      'সেটিংসে না বদলালে ছবি ও ফাইল শুধু Wi-Fi-তে আপলোড হয়।',
    ),
    keywords: [
      'offline',
      'internet',
      'no net',
      'network',
      'sync',
      'connection',
      'অফলাইন',
      'নেট',
      'ইন্টারনেট',
      'সিঙ্ক',
      'নেটওয়ার্ক',
    ],
  ),
  _article(
    category: 'Account',
    popular: true,
    action: 'DataSafety',
    title: ('Can my company see my leads?', 'আমার লিড কি কোম্পানি দেখতে পারে?'),
    summary: (
      'Leads in your personal workspace are only yours. Leads in a team workspace belong to the team.',
      'ব্যক্তিগত ওয়ার্কস্পেসের লিড শুধু আপনার। টিম ওয়ার্কস্পেসের লিড টিমের।',
    ),
    steps: [
      (
        'Check the workspace name at the top of Home. “Personal” means only you can see what is inside.',
        'হোমের উপরে ওয়ার্কস্পেসের নাম দেখুন। “ব্যক্তিগত” মানে ভেতরের সবকিছু শুধু আপনি দেখেন।',
      ),
      (
        'In a team workspace, your team lead and the owner can see the leads you create there.',
        'টিম ওয়ার্কস্পেসে আপনার তৈরি লিড আপনার টিম লিড ও মালিক দেখতে পান।',
      ),
      (
        'Leads cannot be moved between workspaces, so keep personal contacts in your personal workspace.',
        'এক ওয়ার্কস্পেস থেকে অন্যটিতে লিড সরানো যায় না, তাই ব্যক্তিগত পরিচিতদের ব্যক্তিগত ওয়ার্কস্পেসে রাখুন।',
      ),
      (
        'If you leave a team, its leads stay with the team; your personal workspace and activity record go with you.',
        'টিম ছাড়লে টিমের লিড টিমেই থাকে; ব্যক্তিগত ওয়ার্কস্পেস ও কাজের রেকর্ড আপনার সাথে যায়।',
      ),
    ],
    keywords: [
      'privacy',
      'company see',
      'see my leads',
      'private',
      'who can see',
      'গোপন',
      'কোম্পানি',
      'কে দেখতে',
      'দেখতে পারে',
    ],
  ),
  _article(
    category: 'Leads',
    action: 'AddLead',
    videoSeconds: 75,
    video: 'add-lead',
    title: ('How do I add a lead?', 'কীভাবে লিড যোগ করব?'),
    summary: (
      'Add a lead in under a minute — by typing, by voice or from a visiting card.',
      'এক মিনিটের মধ্যে লিড যোগ করুন — লিখে, মুখে বলে বা ভিজিটিং কার্ড থেকে।',
    ),
    steps: [
      (
        'Tap the green + button in the middle of the bottom bar and choose “Lead”.',
        'নিচের বারের মাঝখানের সবুজ + বোতাম চেপে “লিড” বেছে নিন।',
      ),
      (
        'Type the company or person’s name and the mobile number. If the number is already saved, the app shows that lead so you don’t add it twice.',
        'প্রতিষ্ঠান বা ব্যক্তির নাম আর মোবাইল নম্বর লিখুন। নম্বরটি আগে থেকে থাকলে অ্যাপ সেই লিড দেখাবে, যাতে একই লিড দুবার না হয়।',
      ),
      (
        'Pick the source (Facebook, referral, visit…) and an estimated value if you know it.',
        'উৎস (Facebook, রেফারেল, ভিজিট…) আর জানা থাকলে আনুমানিক মূল্য দিন।',
      ),
      (
        'Tap Save. The lead starts in “To contact” and appears at the top of your list.',
        'সেভ চাপুন। লিডটি “যোগাযোগ বাকি” ধাপে শুরু হবে এবং তালিকার উপরে দেখাবে।',
      ),
    ],
    tip: (
      'In a hurry? Choose “By voice” in the add sheet and just say the name, number and what they need.',
      'তাড়া থাকলে যোগ করার শিটে “মুখে বলে” বেছে নিয়ে নাম, নম্বর আর চাহিদা বলুন।',
    ),
    keywords: [
      'add lead',
      'new lead',
      'create lead',
      'lead',
      'customer',
      'prospect',
      'লিড',
      'নতুন লিড',
      'লিড যোগ',
      'গ্রাহক',
      'কাস্টমার',
    ],
  ),
  _article(
    category: 'FieldWork',
    action: 'NewVisit',
    videoSeconds: 95,
    video: 'visit-check-in',
    title: (
      'How do I check in at a customer visit?',
      'গ্রাহকের কাছে ভিজিটে চেক-ইন কীভাবে করব?',
    ),
    summary: (
      'Check in when you arrive so your visit, time and location are recorded.',
      'পৌঁছেই চেক-ইন করুন, যাতে ভিজিট, সময় ও লোকেশন রেকর্ড হয়।',
    ),
    steps: [
      (
        'Open Visits and tap the planned visit, or tap + to start an unplanned one.',
        'ভিজিট খুলে পরিকল্পিত ভিজিটে চাপুন, অথবা অপরিকল্পিত ভিজিটের জন্য + চাপুন।',
      ),
      (
        'When you reach the customer, tap “Check in”. The app reads your location once, so keep GPS on.',
        'গ্রাহকের কাছে পৌঁছে “চেক-ইন” চাপুন। অ্যাপ একবার লোকেশন নেয়, তাই GPS চালু রাখুন।',
      ),
      (
        'Add a photo of the site or shop front if your manager asks for it.',
        'ম্যানেজার চাইলে সাইট বা দোকানের সামনের ছবি যোগ করুন।',
      ),
      (
        'When you leave, tap “Check out”, pick the outcome and set the next follow-up.',
        'বের হওয়ার সময় “চেক-আউট” চাপুন, ফলাফল বেছে নিন আর পরের ফলো-আপ ঠিক করুন।',
      ),
    ],
    tip: (
      'Check-in works offline too; the location is saved and sent later.',
      'নেট না থাকলেও চেক-ইন হয়; লোকেশন সেভ থাকে, পরে পাঠানো হয়।',
    ),
    keywords: [
      'check in',
      'check-in',
      'checkin',
      'visit',
      'check out',
      'gps',
      'চেক-ইন',
      'চেক ইন',
      'ভিজিট',
      'চেক-আউট',
    ],
  ),
  _article(
    category: 'Sales',
    action: 'NewQuotation',
    readMinutes: 3,
    videoSeconds: 120,
    video: 'send-quotation',
    title: ('How do I send a quotation?', 'কোটেশন কীভাবে পাঠাব?'),
    summary: (
      'Build a quotation from your product list and send it as a PDF on WhatsApp or email.',
      'পণ্যের তালিকা থেকে কোটেশন বানিয়ে PDF হিসেবে WhatsApp বা ইমেইলে পাঠান।',
    ),
    steps: [
      (
        'Open the lead and tap “Quotation”, or use + → Quotation.',
        'লিড খুলে “কোটেশন” চাপুন, অথবা + → কোটেশন।',
      ),
      (
        'Add products — for example 10 × Solar panel 550W and 1 × Hybrid inverter 5kW. Prices come from your product list.',
        'পণ্য যোগ করুন — যেমন ১০ × সোলার প্যানেল ৫৫০W আর ১ × হাইব্রিড ইনভার্টার ৫kW। দাম পণ্যের তালিকা থেকে আসে।',
      ),
      (
        'Add installation, a discount and VAT if needed. The total updates as you go.',
        'দরকার হলে ইনস্টলেশন, ছাড় ও ভ্যাট যোগ করুন। মোট টাকা সাথে সাথে বদলায়।',
      ),
      (
        'Tap “Send” and choose WhatsApp, email or download. The lead moves to the “Quotation” stage.',
        '“পাঠান” চেপে WhatsApp, ইমেইল বা ডাউনলোড বেছে নিন। লিডটি “কোটেশন” ধাপে চলে যাবে।',
      ),
    ],
    tip: (
      'Follow up within 3 days of sending — the Academy lesson “The 3-day rule” shows what to say.',
      'পাঠানোর ৩ দিনের মধ্যে ফলো-আপ করুন — একাডেমির “৩ দিনের নিয়ম” পাঠে কী বলবেন তা আছে।',
    ),
    keywords: [
      'quotation',
      'quote',
      'pdf',
      'estimate',
      'offer',
      'কোটেশন',
      'দামের তালিকা',
      'প্রস্তাব',
    ],
  ),
  _article(
    category: 'Sales',
    action: 'NewCollection',
    videoSeconds: 80,
    video: 'record-collection',
    title: (
      'How do I record a collection?',
      'কালেকশন (টাকা আদায়) কীভাবে লিখব?',
    ),
    summary: (
      'Record a payment against an invoice and send the customer a receipt.',
      'ইনভয়েসের বিপরীতে টাকা জমা লিখুন এবং গ্রাহককে রসিদ পাঠান।',
    ),
    steps: [
      (
        'Tap + → Collection, or open the customer and tap “Collect”.',
        '+ → কালেকশন চাপুন, অথবা গ্রাহক খুলে “আদায়” চাপুন।',
      ),
      (
        'Choose the invoice. The due amount fills in; change it for a part payment.',
        'ইনভয়েস বেছে নিন। বাকি টাকা নিজে থেকেই বসে যায়; আংশিক পেলে অঙ্কটি বদলান।',
      ),
      (
        'Pick how they paid — cash, bKash, Nagad, bank transfer or cheque — and add the transaction ID or cheque number.',
        'কীভাবে দিলেন বেছে নিন — ক্যাশ, বিকাশ, নগদ, ব্যাংক ট্রান্সফার বা চেক — এবং ট্রানজেকশন আইডি বা চেক নম্বর লিখুন।',
      ),
      (
        'Save. A receipt is created that you can share on WhatsApp right away.',
        'সেভ করুন। রসিদ তৈরি হবে, সাথে সাথে WhatsApp-এ পাঠাতে পারবেন।',
      ),
    ],
    tip: (
      'Cheques stay “pending” until you mark them cleared, so your outstanding stays honest.',
      'ক্লিয়ার চিহ্ন না দেওয়া পর্যন্ত চেক “পেন্ডিং” থাকে, তাই বকেয়ার হিসাব ঠিক থাকে।',
    ),
    keywords: [
      'collection',
      'payment',
      'collect',
      'receipt',
      'bkash',
      'nagad',
      'cash',
      'cheque',
      'কালেকশন',
      'আদায়',
      'পেমেন্ট',
      'রসিদ',
      'বিকাশ',
      'টাকা',
    ],
  ),
  _article(
    category: 'Leads',
    action: 'Leads',
    title: (
      'How do I move a lead to the next stage?',
      'লিডকে পরের ধাপে কীভাবে নেব?',
    ),
    summary: (
      'Stages show how close a deal is. Move a lead as soon as something changes.',
      'ধাপ দেখায় বিক্রি কতটা কাছে। কিছু বদলালেই লিডের ধাপ বদলান।',
    ),
    steps: [
      (
        'Open the lead and tap the stage pill under its name.',
        'লিড খুলে নামের নিচের ধাপের পিলে চাপুন।',
      ),
      (
        'Pick the new stage: To contact → Contacted → Interested → Quotation → Won or Lost.',
        'নতুন ধাপ বেছে নিন: যোগাযোগ বাকি → যোগাযোগ হয়েছে → আগ্রহী → কোটেশন → জিতেছি বা হারিয়েছি।',
      ),
      (
        '“Interested” means the customer asked for a price or a sample; “Quotation” means you sent one.',
        '“আগ্রহী” মানে গ্রাহক দাম বা স্যাম্পল চেয়েছেন; “কোটেশন” মানে আপনি কোটেশন পাঠিয়েছেন।',
      ),
      (
        'If you mark a lead Lost, pick the reason. Reasons help the team see why deals slip.',
        'হারিয়েছি দিলে কারণ বেছে নিন। কারণ দেখে টিম বুঝতে পারে কেন বিক্রি হাতছাড়া হয়।',
      ),
    ],
    tip: (
      'On the board view you can drag a card from one stage to the next.',
      'বোর্ড ভিউতে কার্ড টেনে এক ধাপ থেকে আরেক ধাপে নিতে পারেন।',
    ),
    keywords: [
      'stage',
      'pipeline',
      'move lead',
      'interested',
      'won',
      'lost',
      'board',
      'ধাপ',
      'আগ্রহী',
      'জিতেছি',
      'হারিয়েছি',
      'পাইপলাইন',
    ],
  ),
  _article(
    category: 'Leads',
    action: 'LogCall',
    title: ('How do I log a call or a note?', 'কল বা নোট কীভাবে লিখে রাখব?'),
    summary: (
      'Every call and note goes on the lead’s timeline, so anyone can pick up where you left off.',
      'প্রতিটি কল ও নোট লিডের টাইমলাইনে থাকে, যাতে যে কেউ আপনার পরে কাজ ধরতে পারে।',
    ),
    steps: [
      (
        'Tap + → Call log or Note, then pick the lead.',
        '+ → কল লগ বা নোট চাপুন, তারপর লিড বেছে নিন।',
      ),
      (
        'For a call, choose the outcome: talked, no answer, busy or call back later.',
        'কলের জন্য ফলাফল বেছে নিন: কথা হয়েছে, ধরেনি, ব্যস্ত বা পরে কল করতে বলেছে।',
      ),
      (
        'Write what was said in a line or two — Bangla, English or both.',
        'কী কথা হলো এক-দুই লাইনে লিখুন — বাংলা, ইংরেজি বা দুটো মিলিয়ে।',
      ),
      (
        'Set the next follow-up date so the lead does not go cold.',
        'পরের ফলো-আপের তারিখ দিন, যাতে লিড ঠান্ডা না হয়ে যায়।',
      ),
    ],
    tip: (
      'Calls made from the lead’s call button are timed and logged for you.',
      'লিডের কল বোতাম থেকে করা কলের সময় নিজে থেকেই লেখা হয়।',
    ),
    keywords: [
      'call log',
      'log call',
      'note',
      'activity',
      'timeline',
      'কল লগ',
      'নোট',
      'টাইমলাইন',
    ],
  ),
  _article(
    category: 'Leads',
    action: 'LeadVoice',
    title: ('Adding a lead by voice', 'মুখে বলে লিড যোগ'),
    summary: (
      'Say the details in Bangla or English and the app fills in the form.',
      'বাংলা বা ইংরেজিতে তথ্য বলুন, অ্যাপ ফর্ম পূরণ করে দেবে।',
    ),
    steps: [
      (
        'Tap + → By voice and allow the microphone the first time.',
        '+ → মুখে বলে চাপুন, প্রথমবার মাইক্রোফোনের অনুমতি দিন।',
      ),
      (
        'Speak naturally: “Masud Traders, Mirpur, 01711 234567, wants a 3 kW home system.”',
        'স্বাভাবিকভাবে বলুন: “মাসুদ ট্রেডার্স, মিরপুর, ০১৭১১ ২৩৪৫৬৭, ৩ কিলোওয়াটের হোম সিস্টেম চান।”',
      ),
      (
        'Check the filled fields — numbers especially — and correct anything misheard.',
        'পূরণ হওয়া ঘরগুলো দেখুন — বিশেষ করে নম্বর — ভুল শোনা কিছু থাকলে ঠিক করুন।',
      ),
      ('Tap Save.', 'সেভ চাপুন।'),
    ],
    tip: (
      'Voice works best in a quiet place and needs internet.',
      'শান্ত জায়গায় ভয়েস সবচেয়ে ভালো কাজ করে, আর এর জন্য ইন্টারনেট লাগে।',
    ),
    keywords: [
      'voice',
      'speak',
      'microphone',
      'mic',
      'ভয়েস',
      'মুখে বলে',
      'মাইক',
    ],
  ),
  _article(
    category: 'Tasks',
    action: 'NewTask',
    title: (
      'How do I set a follow-up reminder?',
      'ফলো-আপের রিমাইন্ডার কীভাবে দেব?',
    ),
    summary: (
      'Create a task with a time and the app reminds you, even when it is closed.',
      'সময়সহ কাজ তৈরি করুন, অ্যাপ বন্ধ থাকলেও মনে করিয়ে দেবে।',
    ),
    steps: [
      (
        'Tap + → Task, or open a lead and tap “Task”.',
        '+ → কাজ চাপুন, অথবা লিড খুলে “কাজ” চাপুন।',
      ),
      (
        'Write what to do, like “Call Karim Textiles about the inverter price”.',
        'কী করবেন লিখুন, যেমন “ইনভার্টারের দাম নিয়ে করিম টেক্সটাইলসকে কল”।',
      ),
      (
        'Pick the date and time, and a reminder 15 minutes or 1 hour before.',
        'তারিখ ও সময় দিন, আর ১৫ মিনিট বা ১ ঘণ্টা আগে রিমাইন্ডার।',
      ),
      (
        'Save. Today’s tasks appear on Home; overdue ones turn red.',
        'সেভ করুন। আজকের কাজ হোমে দেখাবে; সময় পেরোলে লাল হয়ে যাবে।',
      ),
    ],
    tip: (
      'Team leads can assign a task to a member; the member gets a notification.',
      'টিম লিড সদস্যকে কাজ দিতে পারেন; সদস্য নোটিফিকেশন পাবেন।',
    ),
    keywords: [
      'task',
      'reminder',
      'follow up',
      'follow-up',
      'remind',
      'todo',
      'কাজ',
      'রিমাইন্ডার',
      'ফলো-আপ',
      'মনে করিয়ে',
    ],
  ),
  _article(
    category: 'FieldWork',
    action: 'Attendance',
    readMinutes: 3,
    title: (
      'How do attendance and live location work?',
      'হাজিরা ও লাইভ লোকেশন কীভাবে কাজ করে?',
    ),
    summary: (
      'Start your day with a check-in; location is shared only while you are on duty.',
      'চেক-ইন দিয়ে দিন শুরু করুন; শুধু ডিউটির সময়েই লোকেশন শেয়ার হয়।',
    ),
    steps: [
      (
        'Open Attendance and tap “Start day” when you begin work.',
        'কাজ শুরু করলে হাজিরা খুলে “দিন শুরু” চাপুন।',
      ),
      (
        'While you are checked in, your route is recorded every few minutes so visits show on the map.',
        'চেক-ইন থাকা অবস্থায় কয়েক মিনিট পরপর রুট রেকর্ড হয়, যাতে মানচিত্রে ভিজিট দেখা যায়।',
      ),
      (
        'Tap “End day” when you finish. Tracking stops immediately.',
        'কাজ শেষে “দিন শেষ” চাপুন। ট্র্যাকিং সাথে সাথে বন্ধ হয়।',
      ),
      (
        'Missed a check-in? Ask your team lead to correct it from the attendance calendar.',
        'চেক-ইন করতে ভুলে গেছেন? হাজিরার ক্যালেন্ডার থেকে টিম লিডকে ঠিক করে দিতে বলুন।',
      ),
    ],
    tip: (
      'Live tracking is part of the Field Force add-on and always asks for your consent first.',
      'লাইভ ট্র্যাকিং ফিল্ড ফোর্স অ্যাড-অনের অংশ এবং সবসময় আগে আপনার সম্মতি চায়।',
    ),
    keywords: [
      'attendance',
      'tracking',
      'live location',
      'start day',
      'end day',
      'duty',
      'হাজিরা',
      'ট্র্যাকিং',
      'লাইভ',
      'ডিউটি',
    ],
  ),
  _article(
    category: 'Account',
    action: 'Plan',
    title: ('Plans, limits and upgrading', 'প্ল্যান, সীমা ও আপগ্রেড'),
    summary: (
      'See what your plan includes and what happens when you reach a limit.',
      'আপনার প্ল্যানে কী আছে আর সীমা ছুঁলে কী হয় তা দেখুন।',
    ),
    steps: [
      (
        'Open More → Plan and usage to see users, records, storage and card scans this month.',
        'আরও → প্ল্যান ও ব্যবহার খুলে এ মাসের ইউজার, রেকর্ড, স্টোরেজ ও কার্ড স্ক্যান দেখুন।',
      ),
      (
        'Reaching a limit deletes nothing — you just cannot add more of that item until next month or an upgrade.',
        'সীমা ছুঁলে কিছু মোছে না — শুধু পরের মাস বা আপগ্রেড পর্যন্ত ওই জিনিস আর যোগ করা যায় না।',
      ),
      (
        'Tap “Upgrade”, pick a plan and pay with bKash, Nagad or card.',
        '“আপগ্রেড” চেপে প্ল্যান বেছে নিন এবং বিকাশ, নগদ বা কার্ডে টাকা দিন।',
      ),
      (
        'The new limits apply right away for the whole workspace.',
        'নতুন সীমা সাথে সাথে পুরো ওয়ার্কস্পেসে চালু হয়।',
      ),
    ],
    tip: (
      'Only the owner can change the plan. Members see a request button instead.',
      'শুধু মালিক প্ল্যান বদলাতে পারেন। সদস্যরা এর বদলে অনুরোধের বোতাম দেখেন।',
    ),
    keywords: [
      'plan',
      'pricing',
      'upgrade',
      'limit',
      'quota',
      'pro',
      'free plan',
      'billing',
      'subscription',
      'প্ল্যান',
      'আপগ্রেড',
      'সীমা',
      'বিল',
      'ফ্রি',
    ],
  ),
  _article(
    category: 'Account',
    action: 'DataSafety',
    title: (
      'Downloading your data and backups',
      'আপনার ডেটা ডাউনলোড ও ব্যাকআপ',
    ),
    summary: (
      'Your data is backed up daily, and you can download all of it at any time.',
      'আপনার ডেটার প্রতিদিন ব্যাকআপ হয়, আর যেকোনো সময় সব ডাউনলোড করতে পারেন।',
    ),
    steps: [
      (
        'Open Help → Data safety and tap “Download my data”.',
        'সাহায্য → তথ্যের নিরাপত্তা খুলে “আমার ডেটা ডাউনলোড” চাপুন।',
      ),
      (
        'We prepare CSV files for leads, contacts, tasks and sales, plus your uploaded files.',
        'লিড, কনট্যাক্ট, কাজ ও বিক্রির CSV ফাইল আর আপনার আপলোড করা ফাইল আমরা গুছিয়ে দিই।',
      ),
      (
        'You get a notification with a download link, usually within an hour.',
        'সাধারণত এক ঘণ্টার মধ্যে ডাউনলোড লিংকসহ নোটিফিকেশন পাবেন।',
      ),
      (
        'Deleted a record by mistake? It can be restored for 30 days — contact support.',
        'ভুল করে রেকর্ড মুছেছেন? ৩০ দিন পর্যন্ত ফেরানো যায় — সাপোর্টে যোগাযোগ করুন।',
      ),
    ],
    tip: ('Backups are kept for 35 days.', 'ব্যাকআপ ৩৫ দিন রাখা হয়।'),
    keywords: [
      'backup',
      'download',
      'export',
      'csv',
      'restore',
      'deleted',
      'ব্যাকআপ',
      'ডাউনলোড',
      'এক্সপোর্ট',
      'মুছে',
      'ফেরানো',
    ],
  ),
  _article(
    category: 'Sales',
    action: 'Outstanding',
    title: ('Following up on unpaid invoices', 'বকেয়া ইনভয়েসের ফলো-আপ'),
    summary: (
      'See who owes you, how much and for how long, then remind them in one tap.',
      'কে কত টাকা কতদিন ধরে বাকি রেখেছেন দেখুন, তারপর এক চাপে মনে করিয়ে দিন।',
    ),
    steps: [
      (
        'Open Sales → Outstanding. The oldest dues come first.',
        'বিক্রি → বকেয়া খুলুন। সবচেয়ে পুরোনো বাকি আগে দেখায়।',
      ),
      (
        'Tap a customer to see each invoice and its due date.',
        'গ্রাহকে চাপ দিয়ে প্রতিটি ইনভয়েস ও তার শেষ তারিখ দেখুন।',
      ),
      (
        'Tap “Remind” to send a polite SMS or WhatsApp with the amount and your bKash number.',
        '“মনে করান” চেপে টাকার অঙ্ক আর আপনার বিকাশ নম্বরসহ ভদ্রভাবে SMS বা WhatsApp পাঠান।',
      ),
      (
        'When they pay, record the collection so the balance updates.',
        'টাকা দিলে কালেকশন লিখে রাখুন, যাতে বাকির হিসাব ঠিক হয়।',
      ),
    ],
    keywords: [
      'outstanding',
      'due',
      'unpaid',
      'invoice',
      'owe',
      'বকেয়া',
      'বাকি',
      'ইনভয়েস',
      'পাওনা',
    ],
  ),
  _article(
    category: 'Team',
    action: 'TeamChat',
    title: ('Talking to your team about a lead', 'লিড নিয়ে টিমের সাথে কথা'),
    summary: (
      'Every lead has its own discussion, so messages stay next to the deal.',
      'প্রতিটি লিডের আলাদা আলোচনা থাকে, তাই কথাবার্তা বিক্রির পাশেই থাকে।',
    ),
    steps: [
      (
        'Open the lead and tap “Discuss”. A thread for that lead opens.',
        'লিড খুলে “আলোচনা” চাপুন। ওই লিডের থ্রেড খুলবে।',
      ),
      (
        'Type @ and a name to mention a teammate; they get a notification.',
        'সহকর্মীকে জানাতে @ লিখে নাম দিন; তিনি নোটিফিকেশন পাবেন।',
      ),
      (
        'Share photos, quotations or voice notes in the thread.',
        'থ্রেডে ছবি, কোটেশন বা ভয়েস নোট শেয়ার করুন।',
      ),
      (
        'Find all your conversations under More → Chat.',
        'সব আলোচনা পাবেন আরও → চ্যাট-এ।',
      ),
    ],
    keywords: [
      'chat',
      'message',
      'discuss',
      'mention',
      'conversation',
      'চ্যাট',
      'মেসেজ',
      'আলোচনা',
    ],
  ),
  _article(
    category: 'GettingStarted',
    action: 'Language',
    title: (
      'Changing the language and experience level',
      'ভাষা ও অভিজ্ঞতার লেভেল বদলানো',
    ),
    summary: (
      'Use the app in Bangla or English, and choose how much it shows you.',
      'অ্যাপ বাংলা বা ইংরেজিতে চালান, আর কতটা দেখাবে তা ঠিক করুন।',
    ),
    steps: [
      (
        'Tap the বাং / EN pill at the top of most screens to switch language instantly.',
        'বেশিরভাগ স্ক্রিনের উপরের বাং / EN পিলে চাপলে সাথে সাথে ভাষা বদলায়।',
      ),
      (
        'Open More → Settings → Language and level to choose Easy, Standard or Advanced.',
        'আরও → সেটিংস → ভাষা ও লেভেল খুলে Easy, Standard বা Advanced বেছে নিন।',
      ),
      (
        'Easy shows big buttons and short forms. Standard adds sales and reports. Advanced adds pipelines and custom fields.',
        'Easy-তে বড় বোতাম ও ছোট ফর্ম। Standard-এ বিক্রি ও রিপোর্ট যোগ হয়। Advanced-এ পাইপলাইন ও কাস্টম ঘর।',
      ),
      (
        'If the owner has fixed a level for the team, you see a lock next to it.',
        'মালিক টিমের জন্য লেভেল ঠিক করে দিলে পাশে তালা দেখাবেন।',
      ),
    ],
    keywords: [
      'language',
      'bangla',
      'english',
      'level',
      'easy',
      'advanced',
      'ভাষা',
      'বাংলা',
      'ইংরেজি',
      'লেভেল',
    ],
  ),
  _article(
    category: 'GettingStarted',
    title: ('Personal and team workspaces', 'ব্যক্তিগত ও টিম ওয়ার্কস্পেস'),
    summary: (
      'One login, several workspaces — your own and one for each team you belong to.',
      'এক লগইনে কয়েকটি ওয়ার্কস্পেস — নিজের একটি আর প্রতিটি টিমের জন্য একটি।',
    ),
    steps: [
      (
        'Tap the workspace name at the top of Home to see all your workspaces.',
        'সব ওয়ার্কস্পেস দেখতে হোমের উপরে ওয়ার্কস্পেসের নামে চাপুন।',
      ),
      (
        'Pick one to switch. Leads, tasks and reports change to that workspace.',
        'বদলাতে একটি বেছে নিন। লিড, কাজ ও রিপোর্ট সেই ওয়ার্কস্পেসের হয়ে যায়।',
      ),
      (
        'Your role can differ in each — owner in your own, member in your employer’s.',
        'প্রতিটিতে ভূমিকা আলাদা হতে পারে — নিজেরটায় মালিক, অফিসেরটায় সদস্য।',
      ),
      (
        'Starting your own team? Create a new team workspace from the same list.',
        'নিজের টিম শুরু করলে একই তালিকা থেকে নতুন টিম ওয়ার্কস্পেস তৈরি করুন।',
      ),
    ],
    keywords: [
      'workspace',
      'switch',
      'personal',
      'team workspace',
      'ওয়ার্কস্পেস',
      'ব্যক্তিগত',
    ],
  ),
  _article(
    category: 'Account',
    action: 'Security',
    title: ('Locking the app with a PIN', 'PIN দিয়ে অ্যাপ লক'),
    summary: (
      'Your PIN keeps customer data safe if your phone is lost or shared.',
      'ফোন হারালে বা অন্য কেউ ধরলে PIN গ্রাহকের তথ্য নিরাপদ রাখে।',
    ),
    steps: [
      ('Open More → Settings → Security.', 'আরও → সেটিংস → নিরাপত্তা খুলুন।'),
      (
        'Change your 4-digit PIN, or turn on fingerprint unlock.',
        '৪ সংখ্যার PIN বদলান, অথবা ফিঙ্গারপ্রিন্ট আনলক চালু করুন।',
      ),
      (
        'Choose how soon the app locks after you leave it: right away, 1 minute or 5 minutes.',
        'অ্যাপ ছাড়ার কতক্ষণ পর লক হবে বেছে নিন: সাথে সাথে, ১ মিনিট বা ৫ মিনিট।',
      ),
      (
        'Forgot the PIN? Sign in again with your mobile number and the SMS code to set a new one.',
        'PIN ভুলে গেছেন? মোবাইল নম্বর ও SMS কোড দিয়ে আবার সাইন ইন করে নতুন PIN দিন।',
      ),
    ],
    keywords: [
      'pin',
      'lock',
      'password',
      'security',
      'fingerprint',
      'forgot',
      'পিন',
      'লক',
      'পাসওয়ার্ড',
      'নিরাপত্তা',
    ],
  ),
  _article(
    category: 'Tasks',
    action: 'NewTask',
    title: ('Planning your day from Home', 'হোম থেকে দিনের পরিকল্পনা'),
    summary: (
      'Home shows today’s tasks, follow-ups due and visits, so you know where to start.',
      'হোমে আজকের কাজ, বাকি ফলো-আপ ও ভিজিট দেখায়, তাই কোথা থেকে শুরু করবেন বোঝা যায়।',
    ),
    steps: [
      (
        'Each morning, open Home and look at “Today”.',
        'প্রতিদিন সকালে হোম খুলে “আজ” অংশটি দেখুন।',
      ),
      (
        'Start with overdue follow-ups — those leads are the most likely to go cold.',
        'সময় পেরোনো ফলো-আপ দিয়ে শুরু করুন — এই লিডগুলোই সবচেয়ে আগে ঠান্ডা হয়।',
      ),
      (
        'Tick tasks as you finish them; swipe one to move it to tomorrow.',
        'কাজ শেষ হলে টিক দিন; কালকে সরাতে সোয়াইপ করুন।',
      ),
      (
        'Use Calendar to see the week and plan visits by area.',
        'সপ্তাহ দেখতে ও এলাকা ধরে ভিজিট সাজাতে ক্যালেন্ডার ব্যবহার করুন।',
      ),
    ],
    keywords: [
      'today',
      'plan my day',
      'calendar',
      'schedule',
      'আজ',
      'পরিকল্পনা',
      'ক্যালেন্ডার',
    ],
  ),
];
