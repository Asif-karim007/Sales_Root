import 'package:salesroot/core/fake/seed_graph.dart';

/// The activity record shown on the career path.
const careerActivity = {'Calls': 1240, 'Visits': 86, 'Wins': 31};

const careerTitle = {
  'Title': 'Sales executive → Team lead',
  'TitleBn': 'সেলস এক্সিকিউটিভ → টিম লিড',
};

List<Map<String, dynamic>> lessonFixtures(SeedGraph graph) {
  final lost = graph
      .leadsOf(SeedGraph.meId)
      .where((lead) => lead.stageId == 6)
      .length;
  return [
    for (final (i, lesson) in _lessons.indexed)
      {
        ...lesson,
        'Id': i + 1,
        if (lesson['Reason'] == 'LostLeads') 'ReasonCount': lost < 1 ? 3 : lost,
      },
  ];
}

Map<String, dynamic> _lesson({
  required String category,
  required (String, String) title,
  required (String, String) summary,
  required int minutes,
  required List<(String, String)> body,
  required List<(String, String)> points,
  required _Quiz quiz,
  (String, String)? subtitle,
  String? action,
  (String, String)? actionLabel,
  int? videoSeconds,
  int progress = 0,
  int? careerStep,
  int? recommended,
  String? reason,
  bool isNew = false,
  bool tip = false,
}) => {
  'Category': category,
  'Title': title.$1,
  'TitleBn': title.$2,
  'Subtitle': ?subtitle?.$1,
  'SubtitleBn': ?subtitle?.$2,
  'Summary': summary.$1,
  'SummaryBn': summary.$2,
  'Minutes': minutes,
  'VideoSeconds': ?videoSeconds,
  'Body': [
    for (final paragraph in body)
      {'Text': paragraph.$1, 'TextBn': paragraph.$2},
  ],
  'Points': [
    for (final point in points) {'Text': point.$1, 'TextBn': point.$2},
  ],
  'Quiz': {
    'Question': quiz.question.$1,
    'QuestionBn': quiz.question.$2,
    'Options': [
      for (final option in quiz.options)
        {'Text': option.$1, 'TextBn': option.$2},
    ],
    'CorrectIndex': quiz.correct,
    'Explanation': quiz.explanation.$1,
    'ExplanationBn': quiz.explanation.$2,
  },
  'Action': ?action,
  'ActionLabel': ?actionLabel?.$1,
  'ActionLabelBn': ?actionLabel?.$2,
  'Progress': progress,
  'CareerStep': ?careerStep,
  'Recommended': ?recommended,
  'Reason': ?reason,
  'IsNew': isNew,
  'Tip': tip,
};

class _Quiz {
  const _Quiz(this.question, this.options, this.correct, this.explanation);

  final (String, String) question;
  final List<(String, String)> options;
  final int correct;
  final (String, String) explanation;
}

final List<Map<String, dynamic>> _lessons = [
  _lesson(
    category: 'ColdCalling',
    tip: true,
    minutes: 2,
    videoSeconds: 90,
    action: 'LogCall',
    actionLabel: ('Log your next call', 'পরের কলটি লিখে রাখুন'),
    title: (
      'Say their name in the first 10 seconds',
      'ফোনের প্রথম ১০ সেকেন্ডে নাম বলুন',
    ),
    summary: (
      'People listen when they hear their own name. Use it before you say why you are calling.',
      'নিজের নাম শুনলে মানুষ মন দিয়ে শোনে। কেন ফোন করেছেন বলার আগেই নাম বলুন।',
    ),
    body: [
      (
        'The first ten seconds decide whether the customer keeps listening. Open with their name and yours: “Assalamu alaikum, Jamal bhai — this is Rafiq, we met at the Mirpur trade fair.”',
        'প্রথম দশ সেকেন্ডেই ঠিক হয় গ্রাহক শুনবেন কি না। তাঁর নাম আর আপনার নাম দিয়ে শুরু করুন: “আসসালামু আলাইকুম, জামাল ভাই — আমি রফিক, মিরপুরের মেলায় দেখা হয়েছিল।”',
      ),
      (
        'Then give one reason that matters to them, not to you: “You mentioned the factory’s diesel bill — I have a way to cut it.” Pause and let them answer.',
        'তারপর এমন একটি কারণ বলুন যা তাঁর কাছে গুরুত্বপূর্ণ, আপনার কাছে নয়: “কারখানার ডিজেল খরচের কথা বলেছিলেন — কমানোর একটা উপায় আছে।” থামুন, তাঁকে বলতে দিন।',
      ),
    ],
    points: [
      ('Name first, company second', 'আগে নাম, পরে প্রতিষ্ঠান'),
      ('One reason that helps them', 'তাঁর লাভের একটি কারণ'),
      ('Pause after the first sentence', 'প্রথম বাক্যের পর থামুন'),
    ],
    quiz: const _Quiz(
      (
        'What should you say first on a cold call?',
        'কোল্ড কলে প্রথমে কী বলবেন?',
      ),
      [
        ('Your product’s price', 'পণ্যের দাম'),
        ('The customer’s name', 'গ্রাহকের নাম'),
        ('Your company’s history', 'আপনার প্রতিষ্ঠানের ইতিহাস'),
      ],
      1,
      (
        'Hearing their name makes people pay attention, so use it before anything else.',
        'নিজের নাম শুনলে মানুষ মনোযোগ দেয়, তাই সবকিছুর আগে নাম বলুন।',
      ),
    ),
  ),
  _lesson(
    category: 'Closing',
    isNew: true,
    recommended: 1,
    reason: 'LostLeads',
    minutes: 3,
    action: 'Leads',
    actionLabel: ('Open my leads', 'আমার লিড খুলুন'),
    title: ('Learning from lost leads', 'হারানো লিড থেকে শেখা'),
    summary: (
      'Every lost lead has a reason. Spotting the pattern wins you the next one.',
      'প্রতিটি হারানো লিডের পেছনে কারণ থাকে। ধরনটা বুঝলে পরেরটা জেতা যায়।',
    ),
    body: [
      (
        'When you mark a lead Lost, the app asks why. Look at your last ten: is it mostly price, timing or a competitor?',
        'লিড হারিয়েছি দিলে অ্যাপ কারণ জানতে চায়। শেষ দশটি দেখুন: বেশিরভাগ কি দাম, সময়, নাকি প্রতিযোগী?',
      ),
      (
        'If it is price, you are probably quoting before the customer sees the saving. Show the monthly diesel or electricity bill you will cut before you show the total.',
        'দাম হলে সম্ভবত গ্রাহক সাশ্রয় বোঝার আগেই আপনি দাম বলছেন। মোট দাম দেখানোর আগে দেখান মাসে কত ডিজেল বা বিদ্যুৎ বিল কমবে।',
      ),
      (
        'Call one lost customer a month later. Ask kindly what made them choose — many will tell you, and some come back.',
        'এক মাস পর একজন হারানো গ্রাহককে ফোন করুন। নরমভাবে জিজ্ঞেস করুন কেন অন্যটি বেছে নিলেন — অনেকেই বলবেন, কেউ কেউ ফিরেও আসবেন।',
      ),
    ],
    points: [
      ('Always pick a lost reason', 'সবসময় হারানোর কারণ দিন'),
      ('Look for the pattern in your last ten', 'শেষ দশটিতে ধরন খুঁজুন'),
      ('Call back after a month', 'এক মাস পর আবার ফোন করুন'),
    ],
    quiz: const _Quiz(
      (
        'Most of your lost leads say “price”. What should you change first?',
        'বেশিরভাগ হারানো লিডের কারণ “দাম”। প্রথমে কী বদলাবেন?',
      ),
      [
        ('Give a bigger discount', 'আরও বেশি ছাড় দেব'),
        ('Show the saving before the price', 'দামের আগে সাশ্রয় দেখাব'),
        ('Stop calling small customers', 'ছোট গ্রাহকদের ফোন করা বন্ধ করব'),
      ],
      1,
      (
        'Customers who see the monthly saving first judge the price against it, not against a cheaper quote.',
        'যে গ্রাহক আগে মাসিক সাশ্রয় দেখেন, তিনি দামটা সাশ্রয়ের সাথে তুলনা করেন, সস্তা কোটেশনের সাথে নয়।',
      ),
    ),
  ),
  _lesson(
    category: 'FollowUp',
    recommended: 2,
    reason: 'Continue',
    minutes: 2,
    videoSeconds: 120,
    progress: 40,
    action: 'NewTask',
    actionLabel: ('Set the follow-up in the app', 'অ্যাপে ফলো-আপ ঠিক করুন'),
    title: ('The 3-day rule after a quotation', 'কোটেশনের পর ৩ দিনের নিয়ম'),
    summary: (
      'If you do not follow up within 3 days of a quotation, your chance of winning halves. What to say and when.',
      'কোটেশন পাঠানোর ৩ দিনের মধ্যে ফলো-আপ না করলে জেতার সম্ভাবনা অর্ধেক হয়ে যায়। কী বলবেন, কখন বলবেন।',
    ),
    body: [
      (
        'A quotation is a question, not an answer. The customer is comparing, asking family, waiting for the owner. If you go quiet, the last seller who called usually wins.',
        'কোটেশন একটা প্রশ্ন, উত্তর নয়। গ্রাহক তুলনা করছেন, পরিবারের পরামর্শ নিচ্ছেন, মালিকের অপেক্ষায় আছেন। আপনি চুপ থাকলে সাধারণত শেষে যিনি ফোন করেছেন তিনিই জেতেন।',
      ),
      (
        'Day 1 is a short check that it arrived. Day 3 is for questions — technical ones are a buying sign. On day 7, bring something new: a photo from a similar job, a payback sum, a warranty detail.',
        '১ম দিন শুধু জানুন পৌঁছেছে কি না। ৩য় দিন প্রশ্নের জন্য — কারিগরি প্রশ্ন কেনার লক্ষণ। ৭ম দিনে নতুন কিছু দিন: একই রকম কাজের ছবি, খরচ উঠে আসার হিসাব, ওয়ারেন্টির তথ্য।',
      ),
    ],
    points: [
      ('Day 1: “Did you receive it?”', 'দিন ১: “পেয়েছেন কি?”'),
      ('Day 3: “Any questions?”', 'দিন ৩: “কোনো প্রশ্ন আছে?”'),
      (
        'Day 7: offer something new — value, not discount',
        'দিন ৭: নতুন কিছু দিন — ছাড় নয়, মূল্য',
      ),
    ],
    quiz: const _Quiz(
      (
        'It is day 7 and the customer is still deciding. What do you send?',
        '৭ম দিন, গ্রাহক এখনো ভাবছেন। কী পাঠাবেন?',
      ),
      [
        ('A 10% discount', '১০% ছাড়'),
        (
          'A photo and numbers from a similar installation',
          'একই রকম ইনস্টলেশনের ছবি ও হিসাব',
        ),
        ('The same quotation again', 'একই কোটেশন আবার'),
      ],
      1,
      (
        'Something new and useful keeps the conversation going without cutting your margin.',
        'নতুন ও কাজের কিছু দিলে লাভ না কমিয়েই কথা চালিয়ে যাওয়া যায়।',
      ),
    ),
  ),
  _lesson(
    category: 'Closing',
    recommended: 3,
    minutes: 4,
    progress: 100,
    action: 'NewQuotation',
    actionLabel: ('Revise a quotation', 'কোটেশন সংশোধন করুন'),
    title: ('Negotiating on price', 'দাম নিয়ে দরকষাকষি'),
    summary: (
      'Hold your price by trading, not giving: every discount gets something back.',
      'দাম ধরে রাখুন বিনিময়ে, দান করে নয়: প্রতিটি ছাড়ের বদলে কিছু নিন।',
    ),
    body: [
      (
        'When a customer says “too expensive”, ask “compared to what?” Often they are comparing a 5 kW hybrid system with a 3 kW IPS. Line the two up item by item.',
        'গ্রাহক “অনেক দাম” বললে জিজ্ঞেস করুন “কিসের তুলনায়?” প্রায়ই তাঁরা ৫ কিলোওয়াট হাইব্রিড সিস্টেমকে ৩ কিলোওয়াট IPS-এর সাথে তুলনা করেন। দুটো জিনিস ধরে ধরে পাশাপাশি রাখুন।',
      ),
      (
        'If you must move, trade: a lower price for a larger advance, a faster decision, or dropping the free maintenance visit. Never cut the price just to be liked.',
        'ছাড় দিতেই হলে বিনিময় করুন: কম দামের বদলে বেশি অগ্রিম, দ্রুত সিদ্ধান্ত, বা বিনামূল্যের মেইনটেন্যান্স ভিজিট বাদ। শুধু ভালো লাগানোর জন্য দাম কমাবেন না।',
      ),
    ],
    points: [
      ('Ask “compared to what?”', 'জিজ্ঞেস করুন “কিসের তুলনায়?”'),
      ('Compare item by item', 'জিনিস ধরে তুলনা করুন'),
      ('Every discount is a trade', 'প্রতিটি ছাড় একটা বিনিময়'),
    ],
    quiz: const _Quiz(
      (
        'The customer asks for ৳ 20,000 off. What is the best reply?',
        'গ্রাহক ৳ ২০,০০০ কম চাইছেন। সবচেয়ে ভালো উত্তর কোনটি?',
      ),
      [
        ('“Okay, done.”', '“ঠিক আছে, দিলাম।”'),
        (
          '“I can if you pay 60% in advance this week.”',
          '“এ সপ্তাহে ৬০% অগ্রিম দিলে পারব।”',
        ),
        ('“Prices are fixed, sorry.”', '“দাম ঠিক করা, দুঃখিত।”'),
      ],
      1,
      (
        'Trading keeps the deal fair and moves it forward.',
        'বিনিময় করলে চুক্তিটা ন্যায্য থাকে আর এগিয়েও যায়।',
      ),
    ),
  ),
  _lesson(
    category: 'ColdCalling',
    minutes: 3,
    action: 'LogCall',
    actionLabel: ('Log a call', 'কল লগ করুন'),
    title: ('Getting past the front desk', 'রিসেপশন পার হওয়া'),
    summary: (
      'The receptionist is not a wall. Treat them as the first person you need to help.',
      'রিসেপশনিস্ট দেয়াল নন। তাঁকে প্রথম মানুষ ভাবুন, যাঁকে আপনার সাহায্য করতে হবে।',
    ),
    body: [
      (
        'Ask for help, not for the boss: “I am trying to reach whoever looks after the generator and electricity bills — who would that be?”',
        'বসকে না চেয়ে সাহায্য চান: “জেনারেটর আর বিদ্যুৎ বিল যিনি দেখেন, তাঁর সাথে কথা বলতে চাই — কে হবেন?”',
      ),
      (
        'Write the receptionist’s name in the lead’s note. Next time, greet them by name — people remember those who remember them.',
        'রিসেপশনিস্টের নাম লিডের নোটে লিখে রাখুন। পরের বার নাম ধরে সালাম দিন — যাঁরা মনে রাখেন, মানুষও তাঁদের মনে রাখে।',
      ),
    ],
    points: [
      ('Ask who handles the problem', 'জিজ্ঞেস করুন সমস্যাটা কে দেখেন'),
      ('Save the receptionist’s name', 'রিসেপশনিস্টের নাম সেভ করুন'),
      ('Ask the best time to call back', 'কখন আবার ফোন করা ভালো জেনে নিন'),
    ],
    quiz: const _Quiz(
      (
        'Which opening gets you through most often?',
        'কোন শুরুতে সবচেয়ে বেশি এগোনো যায়?',
      ),
      [
        ('“Put me through to the MD.”', '“এমডির সাথে কথা বলিয়ে দিন।”'),
        (
          '“Who looks after your electricity costs?”',
          '“আপনাদের বিদ্যুৎ খরচ কে দেখেন?”',
        ),
        ('“It is personal.”', '“ব্যক্তিগত বিষয়।”'),
      ],
      1,
      (
        'A clear question about a real problem makes it easy for them to help you.',
        'আসল সমস্যা নিয়ে পরিষ্কার প্রশ্ন করলে তাঁদের পক্ষে সাহায্য করা সহজ হয়।',
      ),
    ),
  ),
  _lesson(
    category: 'ColdCalling',
    minutes: 2,
    action: 'Leads',
    actionLabel: ('Open my leads', 'আমার লিড খুলুন'),
    title: ('Calling a lead from Facebook', 'Facebook থেকে আসা লিডে ফোন'),
    summary: (
      'Facebook leads cool down in hours. Call within 30 minutes and mention their message.',
      'Facebook লিড কয়েক ঘণ্টায় ঠান্ডা হয়ে যায়। ৩০ মিনিটের মধ্যে ফোন করুন আর তাঁর মেসেজের কথা বলুন।',
    ),
    body: [
      (
        'Someone who wrote “price?” on your page is comparing three sellers right now. The first one who calls with a clear answer usually gets the visit.',
        'আপনার পেজে যিনি “দাম?” লিখেছেন, তিনি এই মুহূর্তে তিনজন বিক্রেতার তুলনা করছেন। যিনি প্রথমে পরিষ্কার উত্তর নিয়ে ফোন করেন, সাধারণত ভিজিটের সুযোগ তিনিই পান।',
      ),
      (
        'Start with their message: “You asked about solar for your shop — what do you mostly run during load-shedding?” The answer tells you the size before you talk price.',
        'তাঁর মেসেজ দিয়ে শুরু করুন: “আপনার দোকানের জন্য সোলারের কথা জানতে চেয়েছিলেন — লোডশেডিংয়ে সাধারণত কী কী চালান?” উত্তর থেকেই দাম বলার আগে সাইজ বুঝে যাবেন।',
      ),
    ],
    points: [
      ('Call within 30 minutes', '৩০ মিনিটের মধ্যে ফোন'),
      ('Mention their own message', 'তাঁর নিজের মেসেজের কথা বলুন'),
      ('Ask what they need to run', 'কী চালাতে চান জিজ্ঞেস করুন'),
    ],
    quiz: const _Quiz(
      (
        'A Facebook lead asked for a price at 11:00. When should you call?',
        'এক Facebook লিড ১১টায় দাম জানতে চেয়েছেন। কখন ফোন করবেন?',
      ),
      [
        ('Before 11:30', 'সাড়ে ১১টার আগে'),
        ('In the evening', 'সন্ধ্যায়'),
        ('Tomorrow morning', 'কাল সকালে'),
      ],
      0,
      (
        'Interest is highest right after they write and drops quickly.',
        'লেখার ঠিক পরেই আগ্রহ সবচেয়ে বেশি থাকে; তারপর দ্রুত কমে যায়।',
      ),
    ),
  ),
  _lesson(
    category: 'Closing',
    minutes: 3,
    action: 'Leads',
    actionLabel: ('Open my leads', 'আমার লিড খুলুন'),
    title: ('Asking for the order', 'অর্ডার চাওয়া'),
    summary: (
      'Many deals are lost because nobody asked. Learn three simple ways to ask.',
      'অনেক বিক্রি হাতছাড়া হয় কারণ কেউ চায়নি। চাওয়ার তিনটি সহজ উপায় শিখুন।',
    ),
    body: [
      (
        'When the customer’s questions move from “what” to “when” — installation date, payment terms — they are ready. That is your cue.',
        'গ্রাহকের প্রশ্ন যখন “কী” থেকে “কবে”-তে যায় — ইনস্টলেশনের তারিখ, টাকা দেওয়ার নিয়ম — তখন তিনি তৈরি। এটাই আপনার সংকেত।',
      ),
      (
        'Ask plainly: “Shall I book the installation team for Saturday?” or offer a choice: “Do you want the 5 kW or the 8 kW?” Then stay quiet and let them answer.',
        'সরাসরি বলুন: “শনিবারের জন্য ইনস্টলেশন টিম বুক করে দিই?” অথবা পছন্দ দিন: “৫ কিলোওয়াট নেবেন না ৮ কিলোওয়াট?” তারপর চুপ থাকুন, তাঁকে উত্তর দিতে দিন।',
      ),
    ],
    points: [
      ('Listen for “when” questions', '“কবে” প্রশ্ন খেয়াল করুন'),
      ('Ask with a date or a choice', 'তারিখ বা পছন্দ দিয়ে চান'),
      ('Then stay quiet', 'তারপর চুপ থাকুন'),
    ],
    quiz: const _Quiz(
      (
        'The customer asks “How soon can you install?” What do you say?',
        'গ্রাহক জিজ্ঞেস করলেন “কত তাড়াতাড়ি লাগাতে পারবেন?” কী বলবেন?',
      ),
      [
        (
          'Explain the panel technology again',
          'আবার প্যানেলের প্রযুক্তি বোঝাব',
        ),
        (
          '“Shall I book Saturday for you?”',
          '“আপনার জন্য শনিবার বুক করে দিই?”',
        ),
        ('“Let me know when you decide.”', '“সিদ্ধান্ত নিলে জানাবেন।”'),
      ],
      1,
      (
        'A “when” question is a buying signal — answer it with a booking.',
        '“কবে” প্রশ্ন কেনার সংকেত — বুকিং দিয়ে উত্তর দিন।',
      ),
    ),
  ),
  _lesson(
    category: 'FollowUp',
    minutes: 2,
    action: 'LogCall',
    actionLabel: ('Log the follow-up', 'ফলো-আপ লিখে রাখুন'),
    title: (
      'Following up on WhatsApp without being pushy',
      'চাপ না দিয়ে WhatsApp-এ ফলো-আপ',
    ),
    summary: (
      'Short, useful messages get replies. Long sales messages get ignored.',
      'ছোট, কাজের মেসেজের উত্তর আসে। লম্বা বিক্রির মেসেজ কেউ পড়ে না।',
    ),
    body: [
      (
        'Send one thing at a time: a photo of a finished rooftop nearby, a 30-second voice note answering their question, or the warranty card.',
        'একবারে একটা জিনিস পাঠান: কাছাকাছি শেষ হওয়া রুফটপের ছবি, তাঁর প্রশ্নের উত্তরে ৩০ সেকেন্ডের ভয়েস নোট, বা ওয়ারেন্টি কার্ড।',
      ),
      (
        'End with an easy question: “Shall I come by on Thursday to measure the roof?” Never send more than two messages without a reply.',
        'শেষে সহজ একটা প্রশ্ন রাখুন: “বৃহস্পতিবার এসে ছাদ মেপে যাই?” উত্তর না পেলে দুটির বেশি মেসেজ পাঠাবেন না।',
      ),
    ],
    points: [
      ('One useful thing per message', 'প্রতি মেসেজে একটা কাজের জিনিস'),
      ('End with an easy question', 'শেষে সহজ প্রশ্ন'),
      ('At most two without a reply', 'উত্তর ছাড়া সর্বোচ্চ দুটি'),
    ],
    quiz: const _Quiz(
      (
        'You sent two messages and got no reply. What next?',
        'দুটি মেসেজ পাঠিয়েছেন, উত্তর নেই। এরপর কী?',
      ),
      [
        ('Send a third, longer one', 'তৃতীয়টা আরও লম্বা করে পাঠাব'),
        ('Call once at a sensible time', 'ভালো সময়ে একবার ফোন করব'),
        ('Delete the lead', 'লিড মুছে দেব'),
      ],
      1,
      (
        'A short call breaks the silence better than another message.',
        'আরেকটা মেসেজের চেয়ে ছোট একটা ফোন নীরবতা ভালো ভাঙে।',
      ),
    ),
  ),
  _lesson(
    category: 'FollowUp',
    minutes: 3,
    action: 'NewTask',
    actionLabel: ('Set a reminder', 'রিমাইন্ডার দিন'),
    title: ('Reviving a lead that went quiet', 'চুপ হয়ে যাওয়া লিড জাগানো'),
    summary: (
      'A lead that went silent is not lost. Give them an easy way to say yes — or no.',
      'চুপ হয়ে যাওয়া লিড হারানো নয়। হ্যাঁ — বা না — বলার সহজ পথ দিন।',
    ),
    body: [
      (
        'After two weeks of silence, send a kind “closing the file” message: “Shall I close your file for now, or are you still planning the system before summer?”',
        'দুই সপ্তাহ চুপ থাকলে নরমভাবে “ফাইল বন্ধ” মেসেজ দিন: “আপাতত আপনার ফাইলটা বন্ধ রাখব, নাকি গরমের আগে সিস্টেমটা এখনো লাগাতে চান?”',
      ),
      (
        'People reply to this more than to any other message, because it is easy to answer. If they say no, mark the lead Lost with a reason and set a reminder for three months.',
        'এই মেসেজে মানুষ সবচেয়ে বেশি উত্তর দেয়, কারণ উত্তর দেওয়া সহজ। না বললে কারণসহ লিড হারিয়েছি দিন আর তিন মাস পরের রিমাইন্ডার দিন।',
      ),
    ],
    points: [
      ('Wait two weeks, then ask', 'দুই সপ্তাহ অপেক্ষা, তারপর জিজ্ঞেস'),
      ('Make “no” easy to say', '“না” বলাটা সহজ করুন'),
      ('Set a 3-month reminder', '৩ মাসের রিমাইন্ডার দিন'),
    ],
    quiz: const _Quiz(
      (
        'Why does the “close the file” message work?',
        '“ফাইল বন্ধ” মেসেজ কেন কাজ করে?',
      ),
      [
        ('It creates fear', 'এতে ভয় তৈরি হয়'),
        ('It is easy to answer either way', 'যেকোনো উত্তর দেওয়া সহজ'),
        ('It includes a discount', 'এতে ছাড় থাকে'),
      ],
      1,
      (
        'Giving permission to say no removes the pressure, so people reply.',
        'না বলার অনুমতি দিলে চাপ কমে যায়, তাই মানুষ উত্তর দেয়।',
      ),
    ),
  ),
  _lesson(
    category: 'Closing',
    minutes: 4,
    videoSeconds: 150,
    action: 'NewQuotation',
    actionLabel: ('Make a quotation', 'কোটেশন বানান'),
    title: (
      'Explaining solar payback in two minutes',
      'দুই মিনিটে সোলারের খরচ উঠে আসার হিসাব',
    ),
    summary: (
      'Turn a big price into a simple monthly saving the customer can check.',
      'বড় দামকে এমন মাসিক সাশ্রয়ে বদলান, যা গ্রাহক নিজেই মিলিয়ে দেখতে পারেন।',
    ),
    body: [
      (
        'Ask for their last three electricity or diesel bills. A shop paying ৳ 9,000 a month that moves most of its daytime load to a 5 kW system can save around ৳ 5,000–6,000 a month.',
        'শেষ তিন মাসের বিদ্যুৎ বা ডিজেল বিল চান। মাসে ৳ ৯,০০০ বিল দেওয়া একটি দোকান দিনের বেশিরভাগ লোড ৫ কিলোওয়াট সিস্টেমে নিলে মাসে মোটামুটি ৳ ৫,০০০–৬,০০০ বাঁচাতে পারে।',
      ),
      (
        'Divide the system price by the monthly saving to get the months to pay back, then compare it with the 25-year panel warranty. Write it on one line in the quotation note.',
        'সিস্টেমের দামকে মাসিক সাশ্রয় দিয়ে ভাগ করলে কত মাসে খরচ উঠবে তা পাবেন; তারপর প্যানেলের ২৫ বছরের ওয়ারেন্টির সাথে তুলনা করুন। কোটেশনের নোটে এক লাইনে লিখে দিন।',
      ),
    ],
    points: [
      ('Start from their real bills', 'আসল বিল থেকে শুরু করুন'),
      ('Price ÷ monthly saving = months', 'দাম ÷ মাসিক সাশ্রয় = মাস'),
      ('Compare with the 25-year warranty', '২৫ বছরের ওয়ারেন্টির সাথে তুলনা'),
    ],
    quiz: const _Quiz(
      (
        'A system costs ৳ 3,00,000 and saves ৳ 6,000 a month. How long until it pays back?',
        'একটি সিস্টেমের দাম ৳ ৩,০০,০০০, মাসে বাঁচায় ৳ ৬,০০০। খরচ উঠতে কত দিন?',
      ),
      [
        ('About 2 years', 'প্রায় ২ বছর'),
        ('About 4 years', 'প্রায় ৪ বছর'),
        ('About 10 years', 'প্রায় ১০ বছর'),
      ],
      1,
      (
        '3,00,000 ÷ 6,000 = 50 months, a little over four years.',
        '৩,০০,০০০ ÷ ৬,০০০ = ৫০ মাস, চার বছরের একটু বেশি।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 1,
    progress: 100,
    minutes: 3,
    action: 'NewTask',
    actionLabel: ('Plan tomorrow’s calls', 'কালকের কল সাজান'),
    title: ('Planning your day', 'দিনের পরিকল্পনা'),
    subtitle: ('5 calls, 2 visits every morning', 'সকালে ৫ কল, ২ ভিজিট'),
    summary: (
      'A simple morning routine that keeps your pipeline moving every day.',
      'সকালের একটা সহজ রুটিন, যা প্রতিদিন আপনার বিক্রি এগিয়ে রাখে।',
    ),
    body: [
      (
        'Before 10 am, make five calls from your overdue follow-ups and confirm two visits for the day. Calls first — people are fresh and you are not yet stuck in traffic.',
        'সকাল ১০টার আগে বাকি ফলো-আপ থেকে পাঁচটি ফোন করুন আর দিনের দুটি ভিজিট নিশ্চিত করুন। আগে ফোন — তখন মানুষ ঝরঝরে থাকে আর আপনিও যানজটে আটকে নেই।',
      ),
      (
        'Group visits by area: Mirpur and Pallabi on one day, Gulshan and Badda on another. You will fit a third visit into the same fuel.',
        'এলাকা ধরে ভিজিট সাজান: এক দিনে মিরপুর ও পল্লবী, আরেক দিনে গুলশান ও বাড্ডা। একই তেলে তৃতীয় একটা ভিজিটও হয়ে যাবে।',
      ),
    ],
    points: [
      ('5 calls before 10 am', 'সকাল ১০টার আগে ৫ কল'),
      ('2 confirmed visits', '২টি নিশ্চিত ভিজিট'),
      ('Visits grouped by area', 'এলাকা ধরে ভিজিট'),
    ],
    quiz: const _Quiz(
      ('What comes first in the morning routine?', 'সকালের রুটিনে প্রথমে কী?'),
      [
        ('Calls from overdue follow-ups', 'বাকি ফলো-আপের ফোন'),
        ('Checking Facebook', 'Facebook দেখা'),
        (
          'Driving to the farthest customer',
          'সবচেয়ে দূরের গ্রাহকের কাছে যাওয়া',
        ),
      ],
      0,
      (
        'Overdue follow-ups are the leads closest to going cold.',
        'বাকি ফলো-আপের লিডগুলোই সবচেয়ে আগে ঠান্ডা হয়।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 2,
    progress: 100,
    minutes: 3,
    title: ('Selling by asking', 'প্রশ্ন করে বিক্রি'),
    subtitle: ('Need first, product second', 'চাহিদা আগে, পণ্য পরে'),
    summary: (
      'Good questions sell better than a good speech.',
      'ভালো বক্তৃতার চেয়ে ভালো প্রশ্ন বেশি বিক্রি করে।',
    ),
    body: [
      (
        'Before you mention panels or inverters, ask: What do you run during load-shedding? For how many hours a day? What does diesel cost you now?',
        'প্যানেল বা ইনভার্টারের কথা বলার আগে জিজ্ঞেস করুন: লোডশেডিংয়ে কী কী চালান? দিনে কত ঘণ্টা? এখন ডিজেলে কত খরচ হয়?',
      ),
      (
        'Repeat their answer back in one sentence. When customers hear their own problem, your solution sounds like their idea.',
        'তাঁর উত্তরটা এক বাক্যে আবার বলুন। নিজের সমস্যা শুনলে আপনার সমাধানটা গ্রাহকের কাছে নিজের ভাবনা মনে হয়।',
      ),
    ],
    points: [
      ('Ask about the problem first', 'আগে সমস্যা জিজ্ঞেস করুন'),
      ('Get numbers: hours and cost', 'সংখ্যা জানুন: ঘণ্টা ও খরচ'),
      ('Repeat it back', 'আবার বলে শোনান'),
    ],
    quiz: const _Quiz(
      ('Which question should come first?', 'প্রথমে কোন প্রশ্ন?'),
      [
        ('“Do you want our 550 W panel?”', '“আমাদের ৫৫০ ওয়াট প্যানেল নেবেন?”'),
        (
          '“What do you run during load-shedding?”',
          '“লোডশেডিংয়ে কী কী চালান?”',
        ),
        ('“What is your budget?”', '“আপনার বাজেট কত?”'),
      ],
      1,
      (
        'Understanding the need first lets you size the system and the price right.',
        'আগে চাহিদা বুঝলে সিস্টেমের সাইজ আর দাম ঠিকঠাক বলা যায়।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 3,
    progress: 100,
    minutes: 3,
    action: 'NewQuotation',
    actionLabel: ('Make a quotation', 'কোটেশন বানান'),
    title: ('Quotations that win', 'কোটেশন যা জেতে'),
    subtitle: (
      'Clear, complete, sent the same day',
      'পরিষ্কার, পূর্ণ, একই দিনে পাঠানো',
    ),
    summary: (
      'A clear quotation sent the same day beats a cheaper one sent next week.',
      'একই দিনে পাঠানো পরিষ্কার কোটেশন পরের সপ্তাহের সস্তা কোটেশনকে হারায়।',
    ),
    body: [
      (
        'List every item the customer will see on the roof: panels, inverter, battery, structure, cable, installation. Hidden extras later destroy trust.',
        'ছাদে গ্রাহক যা যা দেখবেন সবকিছু লিখুন: প্যানেল, ইনভার্টার, ব্যাটারি, স্ট্রাকচার, ক্যাবল, ইনস্টলেশন। পরে লুকানো খরচ বেরোলে বিশ্বাস নষ্ট হয়।',
      ),
      (
        'Add one line on payback and one on warranty. Send it the same day as the visit, while the customer still remembers your face.',
        'খরচ উঠে আসা নিয়ে এক লাইন আর ওয়ারেন্টি নিয়ে এক লাইন দিন। ভিজিটের দিনই পাঠান, যখন গ্রাহকের আপনার চেহারা মনে আছে।',
      ),
    ],
    points: [
      ('Every item listed', 'প্রতিটি জিনিস লেখা'),
      ('A payback line and a warranty line', 'খরচ ওঠা ও ওয়ারেন্টির লাইন'),
      ('Sent the same day', 'একই দিনে পাঠানো'),
    ],
    quiz: const _Quiz(
      ('When should the quotation go out?', 'কোটেশন কখন পাঠাবেন?'),
      [
        ('The same day as the visit', 'ভিজিটের দিনই'),
        ('After a week', 'এক সপ্তাহ পরে'),
        ('When the customer calls', 'গ্রাহক ফোন করলে'),
      ],
      0,
      (
        'Speed shows you are serious and keeps you first in line.',
        'তাড়াতাড়ি পাঠালে বোঝা যায় আপনি সিরিয়াস, আর আপনি লাইনের প্রথমে থাকেন।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 4,
    progress: 30,
    minutes: 4,
    videoSeconds: 180,
    action: 'Leads',
    actionLabel: ('Open my leads', 'আমার লিড খুলুন'),
    title: ('Handling objections', 'আপত্তি সামলানো'),
    subtitle: ('Price, timing, competitors', 'দাম, সময়, প্রতিযোগী'),
    summary: (
      'An objection is a question in disguise. Find the real question and answer that.',
      'আপত্তি আসলে ছদ্মবেশী প্রশ্ন। আসল প্রশ্নটা খুঁজে সেটার উত্তর দিন।',
    ),
    body: [
      (
        '“Too expensive” usually means “I don’t see the value yet”. “Let me think” often means “I need to ask my partner”. Ask gently: “What would you like to be sure about?”',
        '“অনেক দাম” মানে সাধারণত “এখনো মূল্যটা বুঝিনি”। “একটু ভাবি” প্রায়ই মানে “পার্টনারকে জিজ্ঞেস করতে হবে”। নরমভাবে জিজ্ঞেস করুন: “কোন বিষয়টা নিশ্চিত হতে চান?”',
      ),
      (
        'With competitors, never criticise. Compare facts: panel brand and wattage, inverter warranty, who services it after two years.',
        'প্রতিযোগীর বেলায় কখনো নিন্দা করবেন না। তথ্য দিয়ে তুলনা করুন: প্যানেলের ব্র্যান্ড ও ওয়াট, ইনভার্টারের ওয়ারেন্টি, দুই বছর পর সার্ভিস কে দেবে।',
      ),
      (
        'With timing, tie it to a date they care about: summer load-shedding, Eid sales, a new factory line.',
        'সময়ের বেলায় তাঁর কাছে জরুরি কোনো তারিখের সাথে মেলান: গরমের লোডশেডিং, ঈদের বিক্রি, কারখানার নতুন লাইন।',
      ),
    ],
    points: [
      ('Find the question behind it', 'পেছনের প্রশ্নটা খুঁজুন'),
      ('Compare facts, never criticise', 'তথ্যে তুলনা, নিন্দা নয়'),
      ('Tie timing to their date', 'সময়কে তাঁর তারিখের সাথে মেলান'),
    ],
    quiz: const _Quiz(
      (
        'A customer says “Another company is cheaper.” What do you do?',
        'গ্রাহক বললেন “অন্য কোম্পানি সস্তা।” কী করবেন?',
      ),
      [
        ('Say the other company is bad', 'বলব ওই কোম্পানি খারাপ'),
        (
          'Compare the two quotations item by item',
          'দুই কোটেশন জিনিস ধরে তুলনা করব',
        ),
        ('Match their price immediately', 'সাথে সাথে তাদের দামে দেব'),
      ],
      1,
      (
        'A fair, item-by-item comparison usually shows why the prices differ.',
        'জিনিস ধরে ন্যায্য তুলনা করলে সাধারণত বোঝা যায় দাম কেন আলাদা।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 5,
    minutes: 3,
    action: 'NewCollection',
    actionLabel: ('Record a collection', 'কালেকশন লিখুন'),
    title: ('The collection conversation', 'কালেকশনের কথোপকথন'),
    subtitle: (
      'Asking for money without losing the customer',
      'গ্রাহক না হারিয়ে টাকা চাওয়া',
    ),
    summary: (
      'Collecting is part of selling. Agree the payment plan before installation, then follow it kindly and firmly.',
      'টাকা আদায়ও বিক্রির অংশ। ইনস্টলেশনের আগেই পেমেন্টের নিয়ম ঠিক করুন, তারপর নরম কিন্তু দৃঢ়ভাবে মেনে চলুন।',
    ),
    body: [
      (
        'Write the plan in the quotation: for example 50% advance, 40% on installation, 10% after a week of running. Customers pay what they agreed to in writing.',
        'কোটেশনে নিয়মটা লিখে দিন: যেমন ৫০% অগ্রিম, ৪০% ইনস্টলেশনে, ১০% এক সপ্তাহ চলার পর। লিখিতভাবে যা মেনেছেন, গ্রাহক সেটাই দেন।',
      ),
      (
        'On the due date, call — don’t just text. Ask first how the system is running, then: “The last 10% is due today; shall I send my bKash number?”',
        'শেষ তারিখে ফোন করুন — শুধু মেসেজ নয়। আগে জিজ্ঞেস করুন সিস্টেম কেমন চলছে, তারপর: “শেষ ১০% আজ দেওয়ার কথা; আমার বিকাশ নম্বরটা পাঠাব?”',
      ),
    ],
    points: [
      ('Agree the plan in writing', 'নিয়ম লিখিতভাবে ঠিক করুন'),
      ('Call on the due date', 'শেষ তারিখে ফোন'),
      ('Record every payment', 'প্রতিটি টাকা লিখে রাখুন'),
    ],
    quiz: const _Quiz(
      (
        'When should the payment plan be agreed?',
        'পেমেন্টের নিয়ম কখন ঠিক করবেন?',
      ),
      [
        ('After installation', 'ইনস্টলেশনের পরে'),
        ('In the quotation, before installation', 'কোটেশনে, ইনস্টলেশনের আগে'),
        ('When the customer delays', 'গ্রাহক দেরি করলে'),
      ],
      1,
      (
        'Agreeing up front makes the later conversation easy.',
        'আগে ঠিক করলে পরের কথাবার্তা সহজ হয়।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 6,
    minutes: 3,
    title: ('Coaching a new joiner', 'একজন নতুনকে শেখানো'),
    subtitle: ('Their first two weeks', 'তাঁর প্রথম দুই সপ্তাহ'),
    summary: (
      'A new salesperson learns most by watching you, then being watched by you.',
      'নতুন সেলসপার্সন সবচেয়ে বেশি শেখেন আপনাকে দেখে, তারপর আপনার সামনে করে।',
    ),
    body: [
      (
        'Week one: they come on your visits and listen. After each visit, ask them what the customer really needed.',
        'প্রথম সপ্তাহ: তিনি আপনার ভিজিটে যাবেন আর শুনবেন। প্রতিটি ভিজিটের পর জিজ্ঞেস করুন গ্রাহকের আসলে কী দরকার ছিল।',
      ),
      (
        'Week two: they lead, you stay quiet. Afterwards give one thing that went well and one thing to try next time — never a list of ten.',
        'দ্বিতীয় সপ্তাহ: তিনি কথা বলবেন, আপনি চুপ। পরে একটা ভালো দিক আর পরের বার চেষ্টা করার একটা জিনিস বলুন — দশটার তালিকা কখনো নয়।',
      ),
    ],
    points: [
      ('Week 1: they watch', '১ম সপ্তাহ: তিনি দেখবেন'),
      ('Week 2: you watch', '২য় সপ্তাহ: আপনি দেখবেন'),
      ('One praise, one tip', 'একটা প্রশংসা, একটা পরামর্শ'),
    ],
    quiz: const _Quiz(
      (
        'After the new joiner’s first solo visit, what feedback helps most?',
        'নতুনজনের প্রথম একা ভিজিটের পর কোন মতামত সবচেয়ে কাজের?',
      ),
      [
        ('A list of every mistake', 'সব ভুলের তালিকা'),
        (
          'One thing that went well and one to try',
          'একটা ভালো দিক আর একটা চেষ্টার বিষয়',
        ),
        ('Nothing — they will learn alone', 'কিছু না — নিজেই শিখবে'),
      ],
      1,
      (
        'Small, specific feedback is easy to act on next time.',
        'ছোট, নির্দিষ্ট মতামত পরের বার কাজে লাগানো সহজ।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 7,
    minutes: 3,
    action: 'TeamChat',
    actionLabel: ('Message your team', 'টিমকে মেসেজ দিন'),
    title: ('Running a 15-minute team huddle', '১৫ মিনিটের টিম মিটিং'),
    subtitle: ('Every morning, standing up', 'প্রতিদিন সকালে, দাঁড়িয়ে'),
    summary: (
      'A short daily huddle keeps everyone focused without wasting the morning.',
      'ছোট দৈনিক মিটিং সকাল নষ্ট না করেই সবাইকে মনোযোগী রাখে।',
    ),
    body: [
      (
        'Same time every day, standing, fifteen minutes. Each person says yesterday’s result, today’s two most important visits, and where they are stuck.',
        'প্রতিদিন একই সময়ে, দাঁড়িয়ে, পনেরো মিনিট। প্রত্যেকে বলবেন গতকালের ফল, আজকের সবচেয়ে জরুরি দুটি ভিজিট, আর কোথায় আটকে আছেন।',
      ),
      (
        'Solve problems after the huddle with only the people involved. Close with one number for the day — for example, ten quotations sent across the team.',
        'সমস্যার সমাধান মিটিংয়ের পরে, শুধু সংশ্লিষ্টদের নিয়ে। শেষে দিনের একটা লক্ষ্য বলুন — যেমন পুরো টিম মিলে দশটা কোটেশন পাঠানো।',
      ),
    ],
    points: [
      ('Same time, 15 minutes', 'একই সময়, ১৫ মিনিট'),
      ('Result, plan, blocker', 'ফল, পরিকল্পনা, বাধা'),
      ('One team number for the day', 'দিনের একটা টিম লক্ষ্য'),
    ],
    quiz: const _Quiz(
      (
        'Someone raises a long problem in the huddle. What do you do?',
        'মিটিংয়ে কেউ লম্বা সমস্যা তুললেন। কী করবেন?',
      ),
      [
        ('Solve it there with everyone', 'সবাইকে নিয়ে সেখানেই সমাধান'),
        ('Take it up after the huddle', 'মিটিংয়ের পরে আলাদা করে দেখব'),
        ('Ignore it', 'এড়িয়ে যাব'),
      ],
      1,
      (
        'Keeping the huddle short respects everyone’s morning.',
        'মিটিং ছোট রাখলে সবার সকালের সময় বাঁচে।',
      ),
    ),
  ),
  _lesson(
    category: 'Career',
    careerStep: 8,
    minutes: 4,
    title: ('Reading your team’s numbers', 'টিমের সংখ্যা বোঝা'),
    subtitle: ('Activity, conversion, collection', 'কাজ, রূপান্তর, আদায়'),
    summary: (
      'Three numbers tell you where a salesperson needs help.',
      'তিনটি সংখ্যা বলে দেয় কোন সেলসপার্সনের কোথায় সাহায্য দরকার।',
    ),
    body: [
      (
        'Activity: calls and visits per day. Low activity is a habit problem — fix it with the morning routine.',
        'কাজ: দিনে কত কল ও ভিজিট। কাজ কম মানে অভ্যাসের সমস্যা — সকালের রুটিন দিয়ে ঠিক করুন।',
      ),
      (
        'Conversion: quotations to wins. Lots of activity but few wins is a skill problem — go on visits together.',
        'রূপান্তর: কোটেশন থেকে কতগুলো জেতা। কাজ বেশি কিন্তু জেতা কম মানে দক্ষতার সমস্যা — একসাথে ভিজিটে যান।',
      ),
      (
        'Collection: money in against money invoiced. Slow collection is a terms problem — fix the payment plan in the quotation.',
        'আদায়: ইনভয়েসের বিপরীতে কত টাকা এসেছে। আদায় ধীর মানে শর্তের সমস্যা — কোটেশনে পেমেন্টের নিয়ম ঠিক করুন।',
      ),
    ],
    points: [
      ('Activity → habit', 'কাজ → অভ্যাস'),
      ('Conversion → skill', 'রূপান্তর → দক্ষতা'),
      ('Collection → terms', 'আদায় → শর্ত'),
    ],
    quiz: const _Quiz(
      (
        'A member makes many visits but rarely wins. What is the likely problem?',
        'একজন সদস্য অনেক ভিজিট করেন কিন্তু কম জেতেন। সম্ভাব্য সমস্যা কী?',
      ),
      [
        ('Habit', 'অভ্যাস'),
        ('Skill', 'দক্ষতা'),
        ('Payment terms', 'পেমেন্টের শর্ত'),
      ],
      1,
      (
        'Plenty of activity with few wins points to how the visits are run.',
        'কাজ বেশি কিন্তু জেতা কম হলে বোঝা যায় ভিজিটগুলো কীভাবে হচ্ছে তাতেই সমস্যা।',
      ),
    ),
  ),
];
