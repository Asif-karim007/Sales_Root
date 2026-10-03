import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/pricing.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

/// The invoice that the referral wallet's redemption points at.
const String creditedInvoiceNumber = 'INV-SR-4402';

const Map<String, dynamic> billingCatalogJson = {
  'VatPercent': 5,
  'Plans': [
    {
      'Code': 'Free',
      'Name': 'Free',
      'Rank': 0,
      'PricePerUser': 0,
      'MaxUsers': 1,
      'Records': 500,
      'CardScans': 10,
      'StorageGb': 1,
      'Summary': '1 user · 500 records · 10 scans/mo',
      'SummaryBn': '১ জন · ৫০০ রেকর্ড · ১০ স্ক্যান/মাস',
      'Features': <Map<String, dynamic>>[],
    },
    {
      'Code': 'PersonalPro',
      'Name': 'Personal Pro',
      'Rank': 1,
      'PricePerUser': 199,
      'MaxUsers': 1,
      'Records': 5000,
      'CardScans': 100,
      'StorageGb': 5,
      'Summary': '5,000 leads · quotations & bills · 100 scans',
      'SummaryBn': '৫,০০০ লিড · কোটেশন ও বিল · ১০০ স্ক্যান',
      'Features': [
        {
          'Name': 'Quotations and bills',
          'NameBn': 'কোটেশন ও বিল',
          'Detail': 'quotation, order and invoice PDFs',
          'DetailBn': 'কোটেশন, অর্ডার ও ইনভয়েস PDF',
        },
        {
          'Name': '5,000 records',
          'NameBn': '৫,০০০ রেকর্ড',
          'Detail': 'leads, contacts and companies',
          'DetailBn': 'লিড, কনট্যাক্ট ও কোম্পানি',
        },
        {
          'Name': '100 card scans',
          'NameBn': '১০০ কার্ড স্ক্যান',
          'Detail': 'every month',
          'DetailBn': 'প্রতি মাসে',
        },
      ],
    },
    {
      'Code': 'Team',
      'Name': 'Team',
      'Rank': 2,
      'PricePerUser': 399,
      'Records': 25000,
      'CardScans': 50,
      'StorageGb': 10,
      'Summary': 'Team, chat, collection, leave & expense',
      'SummaryBn': 'টিম, চ্যাট, কালেকশন, ছুটি ও খরচ',
      'Features': [
        {
          'Name': 'Team and roles',
          'NameBn': 'টিম ও রোল',
          'Detail': 'invite members, roles and targets',
          'DetailBn': 'সদস্য আমন্ত্রণ, রোল ও টার্গেট',
        },
        {
          'Name': 'Team chat',
          'NameBn': 'টিম চ্যাট',
          'Detail': 'a thread on every lead',
          'DetailBn': 'প্রতিটি লিডে আলোচনা',
        },
        {
          'Name': 'Collection',
          'NameBn': 'কালেকশন',
          'Detail': 'dues, receipts and reminders',
          'DetailBn': 'বকেয়া, রসিদ ও রিমাইন্ডার',
        },
        {
          'Name': 'Leave and expense',
          'NameBn': 'ছুটি ও খরচ',
          'Detail': 'requests with approval',
          'DetailBn': 'অনুমোদনসহ আবেদন',
        },
      ],
    },
    {
      'Code': 'Business',
      'Name': 'Business',
      'Rank': 3,
      'PricePerUser': 599,
      'Records': 100000,
      'CardScans': 500,
      'StorageGb': 50,
      'Summary': '+ tickets, manager desk, packs, payroll, AI',
      'SummaryBn': '+ টিকিট, ম্যানেজার ডেস্ক, প্যাক, পেরোল, AI',
      'Features': [
        {
          'Name': 'Support tickets',
          'NameBn': 'সাপোর্ট টিকিট',
          'Detail': 'customer issues with SLA',
          'DetailBn': 'গ্রাহকের সমস্যা SLA সহ',
        },
        {
          'Name': 'Manager desk',
          'NameBn': 'ম্যানেজার ডেস্ক',
          'Detail': 'web dashboards and reports',
          'DetailBn': 'ওয়েবে ড্যাশবোর্ড ও রিপোর্ট',
        },
        {
          'Name': 'Industry packs',
          'NameBn': 'ইন্ডাস্ট্রি প্যাক',
          'Detail': 'real estate, education, trading…',
          'DetailBn': 'রিয়েল এস্টেট, শিক্ষা, ট্রেডিং…',
        },
        {
          'Name': 'Payroll',
          'NameBn': 'পেরোল',
          'Detail': 'salary from attendance, payslip SMS',
          'DetailBn': 'হাজিরা থেকে বেতন, পে-স্লিপ SMS',
        },
        {
          'Name': 'AI assistant',
          'NameBn': 'AI সহকারী',
          'Detail': 'who to call, WhatsApp drafts, voice commands',
          'DetailBn': 'কাকে কল দেব, WhatsApp ড্রাফট, ভয়েস কমান্ড',
        },
        {
          'Name': 'Organogram visibility',
          'NameBn': 'সংগঠন অনুযায়ী দেখা',
          'Detail': 'department and branch',
          'DetailBn': 'বিভাগ ও শাখা',
        },
      ],
    },
  ],
  'AddOns': [
    {
      'Code': 'FieldForce',
      'Name': 'Field Force',
      'NameBn': 'ফিল্ড ফোর্স',
      'Detail': 'Visits, route, live tracking, attendance',
      'DetailBn': 'ভিজিট, রুট, লাইভ ট্র্যাকিং, হাজিরা',
      'Kind': 'Recurring',
      'Price': 99,
      'Grants': 'FieldForce',
      'MinPlan': 'Team',
    },
    {
      'Code': 'Growth',
      'Name': 'Growth',
      'NameBn': 'গ্রোথ',
      'Detail': 'Facebook & website leads, WhatsApp inbox, distribution rules',
      'DetailBn': 'Facebook ও ওয়েবসাইট লিড, WhatsApp ইনবক্স, বিতরণ নিয়ম',
      'Kind': 'Recurring',
      'Price': 149,
      'Grants': 'Growth',
      'MinPlan': 'Team',
    },
    {
      'Code': 'Sms1000',
      'Name': 'SMS credits 1,000',
      'NameBn': 'এসএমএস ক্রেডিট ১,০০০',
      'Detail': '1,000 SMS · sender ID SalesRoot',
      'DetailBn': '১,০০০ এসএমএস · সেন্ডার আইডি SalesRoot',
      'Kind': 'Pack',
      'Price': 350,
      'Quota': 'SmsCredits',
      'Amount': 1000,
      'PromptFor': 'SmsCredits',
    },
    {
      'Code': 'Scans200',
      'Name': '+200 card scans',
      'NameBn': '+২০০ কার্ড স্ক্যান',
      'Detail': 'For this month',
      'DetailBn': 'এ মাসের জন্য',
      'Kind': 'Pack',
      'Price': 499,
      'Quota': 'CardScans',
      'Amount': 200,
    },
    {
      'Code': 'Storage10',
      'Name': '+10 GB storage',
      'NameBn': '+১০ GB স্টোরেজ',
      'Detail': 'Chat media and files',
      'DetailBn': 'চ্যাট মিডিয়া ও ফাইল',
      'Kind': 'Pack',
      'Price': 199,
      'Quota': 'Storage',
      'Amount': 10,
      'PromptFor': 'Storage',
    },
    {
      'Code': 'AiAssistant',
      'Name': 'AI assistant',
      'NameBn': 'AI সহকারী',
      'Detail': 'Who to call, WhatsApp drafts, voice commands',
      'DetailBn': 'কাকে কল দেব, WhatsApp ড্রাফট, ভয়েস কমান্ড',
      'Kind': 'Recurring',
      'Price': 79,
      'MinPlan': 'Team',
      'IncludedIn': 'Business',
    },
    {
      'Code': 'Scans50',
      'Name': '+50 scans',
      'NameBn': '+৫০ স্ক্যান',
      'Detail': 'For this month',
      'DetailBn': 'এ মাসের জন্য',
      'Kind': 'Pack',
      'Price': 199,
      'Quota': 'CardScans',
      'Amount': 50,
      'InStore': false,
      'PromptFor': 'CardScans',
    },
  ],
};

final BillingCatalog _catalog = BillingCatalog.fromJson(billingCatalogJson);

const Map<String, dynamic> _bkash = {'Kind': 'Bkash', 'Account': '01711••••67'};
const Map<String, dynamic> _nagad = {'Kind': 'Nagad', 'Account': '01819••••21'};

/// One row: the workspace's subscription.
List<Map<String, dynamic>> subscriptionFixtures(SeedGraph graph) => [
  switch (graph.workspaceId) {
    200 => {
      'Id': 1,
      'PlanCode': 'Team',
      'Seats': 25,
      'Cycle': 'Monthly',
      'ActiveUsers': 18,
      'RenewsAt': AppDateUtils.toApiUtc(graph.daysAhead(3)),
      'AddOns': ['FieldForce'],
      'PaymentMethod': _bkash,
    },
    300 => {
      'Id': 1,
      'PlanCode': 'Business',
      'Seats': 10,
      'Cycle': 'Monthly',
      'ActiveUsers': 6,
      'RenewsAt': AppDateUtils.toApiUtc(graph.daysAhead(3)),
      'AddOns': ['FieldForce', 'Growth'],
      'PaymentMethod': _nagad,
    },
    _ => _freeSubscription,
  },
];

const Map<String, dynamic> _freeSubscription = {
  'Id': 1,
  'PlanCode': 'Free',
  'Seats': 1,
  'Cycle': 'Monthly',
  'ActiveUsers': 1,
  'AddOns': <String>[],
};

List<Map<String, dynamic>> invoiceFixtures(SeedGraph graph) =>
    switch (graph.workspaceId) {
      200 => _teamHistory(graph),
      300 => _businessHistory(graph),
      _ => const [],
    };

List<Map<String, dynamic>> _teamHistory(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  for (var month = 0; month < 20; month++) {
    final seats = (25 - month ~/ 2).clamp(12, 25);
    final addOns = month < 8 ? {'FieldForce'} : <String>{};
    final issued = graph.daysAgo(27 + month * 30, hour: 9, minute: 12);
    rows.add(
      _renewal(
        number: 'INV-SR-${4402 - month * 37}',
        plan: 'Team',
        seats: seats,
        addOns: addOns,
        issued: issued,
        method: _bkash,
        credits: month == 0 ? 500 : 0,
        retriedAt: month == 2 ? issued.add(const Duration(days: 2)) : null,
      ),
    );
  }
  rows
    ..add(
      _pack(
        'Sms1000',
        'INV-SR-4381',
        graph.daysAgo(43, hour: 16, minute: 40),
        _nagad,
      ),
    )
    ..add(
      _pack(
        'Scans50',
        'INV-SR-4320',
        graph.daysAgo(75, hour: 11, minute: 5),
        _bkash,
      ),
    )
    ..add(
      _pack(
        'Storage10',
        'INV-SR-4190',
        graph.daysAgo(160, hour: 12, minute: 30),
        _bkash,
      ),
    )
    ..add(
      _pack(
        'Sms1000',
        'INV-SR-4066',
        graph.daysAgo(250, hour: 15, minute: 10),
        _bkash,
        status: 'Refunded',
      ),
    );
  rows.sort(
    (a, b) => (b['IssuedAt'] as String).compareTo(a['IssuedAt'] as String),
  );
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'Id': rows.length - i},
  ];
}

List<Map<String, dynamic>> _businessHistory(SeedGraph graph) {
  final rows = [
    for (var month = 0; month < 8; month++)
      _renewal(
        number: 'INV-SR-${5120 - month * 29}',
        plan: 'Business',
        seats: (10 - month ~/ 2).clamp(6, 10),
        addOns: {'FieldForce', if (month < 5) 'Growth'},
        issued: graph.daysAgo(27 + month * 30, hour: 10, minute: 2),
        method: _nagad,
      ),
  ];
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'Id': rows.length - i},
  ];
}

Map<String, dynamic> _renewal({
  required String number,
  required String plan,
  required int seats,
  required Set<String> addOns,
  required DateTime issued,
  required Map<String, dynamic> method,
  int credits = 0,
  DateTime? retriedAt,
}) {
  final subscription = Subscription(
    planCode: 'Free',
    seats: seats,
    cycle: BillingCycle.monthly,
    activeUsers: seats,
  );
  final quote = BillingPricing.quote(
    catalog: _catalog,
    current: subscription,
    request: CheckoutRequest(plan: plan, seats: seats, addOns: addOns),
    walletBalance: credits,
    useCredits: credits > 0,
  );
  return {
    'Number': number,
    'Kind': 'Plan',
    'ItemName': plan,
    'ItemNameBn': plan,
    'IssuedAt': AppDateUtils.toApiUtc(issued),
    'PeriodStart': AppDateUtils.toApiUtc(issued),
    'Seats': seats,
    'Status': 'Paid',
    'PaymentMethod': method,
    'RetriedAt': retriedAt == null ? null : AppDateUtils.toApiUtc(retriedAt),
    ...quote.toJson(),
  }..removeWhere((_, value) => value == null);
}

Map<String, dynamic> _pack(
  String code,
  String number,
  DateTime issued,
  Map<String, dynamic> method, {
  String status = 'Paid',
}) {
  final pack = _catalog.addOn(code);
  final quote = BillingPricing.quote(
    catalog: _catalog,
    current: const Subscription(
      planCode: 'Team',
      seats: 1,
      cycle: BillingCycle.monthly,
      activeUsers: 1,
    ),
    request: CheckoutRequest(packs: [code]),
  );
  return {
    'Number': number,
    'Kind': 'Pack',
    'ItemName': pack.name.en,
    'ItemNameBn': pack.name.bn,
    'IssuedAt': AppDateUtils.toApiUtc(issued),
    'Status': status,
    'PaymentMethod': method,
    ...quote.toJson(),
  };
}
