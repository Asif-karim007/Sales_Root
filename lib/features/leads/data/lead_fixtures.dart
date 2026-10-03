import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

const leadSourceFixtures = [
  {'Id': 1, 'Name': 'Facebook', 'NameBn': 'ফেসবুক'},
  {'Id': 2, 'Name': 'Referral', 'NameBn': 'রেফারেল'},
  {'Id': 3, 'Name': 'Walk-in', 'NameBn': 'সরাসরি এসেছেন'},
  {'Id': 4, 'Name': 'Phone call', 'NameBn': 'ফোন কল'},
  {'Id': 5, 'Name': 'Visit', 'NameBn': 'ভিজিট'},
  {'Id': 6, 'Name': 'Website', 'NameBn': 'ওয়েবসাইট'},
  {'Id': 7, 'Name': 'WhatsApp', 'NameBn': 'হোয়াটসঅ্যাপ'},
  {'Id': 8, 'Name': 'Visiting card', 'NameBn': 'ভিজিটিং কার্ড'},
];

const leadTagFixtures = [
  {'Id': 1, 'Name': 'Textile', 'NameBn': 'টেক্সটাইল'},
  {'Id': 2, 'Name': 'Electronics', 'NameBn': 'ইলেকট্রনিক্স'},
  {'Id': 3, 'Name': 'Pharma', 'NameBn': 'ফার্মা'},
  {'Id': 4, 'Name': 'Food', 'NameBn': 'খাদ্য'},
  {'Id': 5, 'Name': 'Construction', 'NameBn': 'নির্মাণ'},
  {'Id': 6, 'Name': 'Retail', 'NameBn': 'খুচরা'},
  {'Id': 7, 'Name': 'Agro', 'NameBn': 'কৃষি'},
  {'Id': 8, 'Name': 'Furniture', 'NameBn': 'ফার্নিচার'},
  {'Id': 9, 'Name': 'Healthcare', 'NameBn': 'স্বাস্থ্যসেবা'},
  {'Id': 10, 'Name': 'Printing', 'NameBn': 'প্রিন্টিং'},
  {'Id': 11, 'Name': 'Rooftop', 'NameBn': 'রুফটপ'},
  {'Id': 12, 'Name': 'Factory', 'NameBn': 'ফ্যাক্টরি'},
  {'Id': 13, 'Name': 'Repeat buyer', 'NameBn': 'পুরনো ক্রেতা'},
  {'Id': 14, 'Name': 'Govt tender', 'NameBn': 'সরকারি টেন্ডার'},
  {'Id': 15, 'Name': 'Net metering', 'NameBn': 'নেট মিটারিং'},
];

const leadInterestFixtures = [
  {'Id': 1, 'Name': 'Solar', 'NameBn': 'সোলার'},
  {'Id': 2, 'Name': 'Inverter', 'NameBn': 'ইনভার্টার'},
  {'Id': 3, 'Name': 'Battery', 'NameBn': 'ব্যাটারি'},
  {'Id': 4, 'Name': 'Servicing', 'NameBn': 'সার্ভিসিং'},
  {'Id': 5, 'Name': 'Installation', 'NameBn': 'ইনস্টলেশন'},
  {'Id': 6, 'Name': 'Street light', 'NameBn': 'স্ট্রিট লাইট'},
  {'Id': 7, 'Name': 'Water pump', 'NameBn': 'সোলার পাম্প'},
];

const leadLostReasonFixtures = [
  {'Id': 1, 'Name': 'Price too high', 'NameBn': 'দাম বেশি'},
  {'Id': 2, 'Name': 'Went to a competitor', 'NameBn': 'প্রতিযোগীর কাছে গেছে'},
  {'Id': 3, 'Name': 'No budget', 'NameBn': 'বাজেট নেই'},
  {'Id': 4, 'Name': 'No response', 'NameBn': 'সাড়া নেই'},
  {'Id': 5, 'Name': 'Other', 'NameBn': 'অন্য কারণ'},
];

const _stageHints = {
  1: ('Not contacted yet', 'এখনো কথা হয়নি'),
  2: ('First contact made', 'প্রথম কথা হয়েছে'),
  3: ('Asked for price or samples', 'দাম বা স্যাম্পল চেয়েছেন'),
  4: ('Quotation sent', 'কোটেশন পাঠানো হয়েছে'),
  5: ('Order confirmed', 'অর্ডার নিশ্চিত'),
  6: ('The deal did not happen', 'ডিল হয়নি'),
};

List<Map<String, dynamic>> leadStageFixtures(SeedGraph graph) => [
  for (final (id, name, nameBn, probability) in SeedGraph.stages)
    {
      'Id': id,
      'Name': name,
      'NameBn': nameBn,
      'Hint': _stageHints[id]?.$1,
      'HintBn': _stageHints[id]?.$2,
      'WinProbability': probability,
      'FunnelOrder': id,
      'IsWon': id == 5,
      'IsLost': id == 6,
    },
];

Map<String, dynamic> leadStageJson(int stageId, DateTime? changedOn) {
  final (id, name, nameBn, _) = SeedGraph.stages.firstWhere(
    (s) => s.$1 == stageId,
  );
  return {
    'Id': id,
    'Name': name,
    'NameBn': nameBn,
    'ChangedOn': jsonUtc(changedOn),
    'IsWon': id == 5,
    'IsLost': id == 6,
  };
}

int leadStageProbability(int stageId) =>
    SeedGraph.stages.firstWhere((s) => s.$1 == stageId).$4;

Map<String, dynamic> leadMemberJson(SeedMember member) => {
  'Id': member.id,
  'Name': member.name,
  'NameBn': member.nameBn,
};

Map<String, dynamic> leadCompanyJson(SeedGraph graph, SeedCompany company) => {
  'Id': company.id,
  'Name': company.name,
  'Industry': company.industry,
  'Area': {'Name': company.area.name, 'NameBn': company.area.nameBn},
  'ContactCount': graph.contactsOf(company.id).length,
};

Map<String, dynamic> leadContactJson(SeedContact contact, {bool? primary}) => {
  'Id': contact.id,
  'Name': contact.name,
  'Designation': contact.designation,
  'Mobile': contact.phone,
  'Email': contact.email,
  'IsPrimary': primary ?? contact.isPrimary,
};

Map<String, dynamic> leadTagNamed(String? name) => leadTagFixtures.firstWhere(
  (tag) => tag['Name'] == name,
  orElse: () => leadTagFixtures[10],
);

List<Map<String, dynamic>> leadFixtures(SeedGraph graph) => [
  for (final seed in graph.leads) _LeadSeed(graph, seed).lead(),
];

List<Map<String, dynamic>> leadActivityFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  for (final seed in graph.leads) {
    for (final row in _LeadSeed(graph, seed).activities()) {
      rows.add({...row, 'Id': rows.length + 1});
    }
  }
  return rows;
}

/// One seeded lead and its history, drawn from a random source keyed by the
/// lead so the lead row and its timeline agree.
class _LeadSeed {
  _LeadSeed(this.graph, this.seed);

  final SeedGraph graph;
  final SeedLead seed;

  Random get _random => graph.random('lead-${seed.id}');

  SeedCompany get _company => graph.company(seed.companyId);

  bool get _hasQuotation => seed.stageId >= 4 && seed.stageId != 6;

  int get _stageDays => min(seed.createdDaysAgo, 2 + seed.id % 9);

  int? get _taskDays {
    if (!seed.isOpen || seed.id % 7 == 3) return null;
    return seed.id % 11 - 3;
  }

  Map<String, dynamic> lead() {
    final random = _random;
    final company = _company;
    final primary = graph.contact(seed.contactId);
    final others = graph
        .contactsOf(company.id)
        .where((c) => c.id != primary.id)
        .take(random.nextInt(2))
        .toList();
    final owner = graph.member(seed.ownerId);
    final taskDays = _taskDays;
    final taskKind = _taskKinds[seed.id % _taskKinds.length];
    final closeDays = seed.isOpen ? 4 + random.nextInt(58) : -_stageDays;
    final lastTouch = min(seed.lastTouchDaysAgo, seed.createdDaysAgo);
    final shared = graph.members.length > 2 && seed.id % 6 == 0
        ? graph.members[(seed.id * 5) % graph.members.length]
        : null;
    final source = leadSourceFixtures.firstWhere(
      (s) => s['Name'] == seed.source,
      orElse: () => leadSourceFixtures.first,
    );
    final quoted = (seed.value * (0.82 + random.nextInt(14) / 100)).round();
    return {
      'Id': seed.id,
      'Code': 'L-${seed.id.toString().padLeft(4, '0')}',
      'LeadName': seed.title,
      'CreatedOn': jsonUtc(graph.daysAgo(seed.createdDaysAgo, hour: 11)),
      'UpdatedOn': jsonUtc(graph.daysAgo(lastTouch, hour: 16)),
      'Company': leadCompanyJson(graph, company),
      'Stage': leadStageJson(seed.stageId, graph.daysAgo(_stageDays)),
      'AssignedTo': leadMemberJson(owner),
      'CreatedBy': leadMemberJson(owner),
      'SharedWith': [
        if (shared != null && shared.id != owner.id) leadMemberJson(shared),
      ],
      'EstimatedAmount': seed.value,
      'EstimatedClosingDate': jsonUtc(graph.daysAhead(closeDays)),
      'DaysToClose': closeDays,
      'WinProbability': leadStageProbability(seed.stageId),
      'Temperature': seed.hot ? 'Hot' : (random.nextBool() ? 'Warm' : 'Cold'),
      'Source': source,
      'Tags': [
        leadTagNamed(company.industry),
        if (seed.id % 4 == 0) leadTagFixtures[10 + seed.id % 5],
      ],
      'Interests': [
        leadInterestFixtures[seed.id % 3],
        if (seed.id % 3 == 0) leadInterestFixtures[3 + seed.id % 4],
      ],
      'PrimaryContact': leadContactJson(primary, primary: true),
      'Contacts': [
        leadContactJson(primary, primary: true),
        for (final contact in others) leadContactJson(contact, primary: false),
      ],
      'LastQuotation': _hasQuotation || (seed.stageId == 3 && seed.id.isEven)
          ? {
              'Id': seed.id,
              'Code': 'Q-${(seed.id + 30).toString().padLeft(4, '0')}',
              'Amount': quoted,
              'Date': jsonUtc(graph.daysAgo(1 + seed.id % 5, hour: 15)),
            }
          : null,
      'WinLoss': seed.stageId == 6
          ? {
              'CauseId': leadLostReasonFixtures[seed.id % 5]['Id'],
              'Cause': leadLostReasonFixtures[seed.id % 5],
              'Note': _lostNotes[seed.id % _lostNotes.length],
            }
          : null,
      'NextTaskId': taskDays == null ? null : 1000 + seed.id,
      'NextTaskTitle': taskDays == null
          ? null
          : _taskTitles[taskKind]?[seed.id % 3],
      'NextTaskType': taskDays == null ? null : taskKind,
      'NextTaskAt': taskDays == null
          ? null
          : jsonUtc(graph.daysAhead(taskDays, hour: 10 + seed.id % 7)),
      'IsDueToday': taskDays == 0,
      'IsOverdue': taskDays != null && taskDays < 0,
      'IsStalled': seed.isOpen && taskDays == null && lastTouch >= 3,
      'DaysInStage': _stageDays,
      'LastActivityOn': jsonUtc(graph.daysAgo(lastTouch, hour: 12)),
      'Comments': seed.id % 3 == 1
          ? _comments[seed.id % _comments.length]
          : null,
    }..removeWhere((_, v) => v == null);
  }

  List<Map<String, dynamic>> activities() {
    final random = _random..nextInt(100);
    final owner = graph.member(seed.ownerId).name;
    final created = seed.createdDaysAgo;
    final rows = <Map<String, dynamic>>[
      _activity(
        'Created',
        graph.daysAgo(created, hour: 11),
        owner,
        description: seed.source,
      ),
    ];
    final touches = 1 + random.nextInt(4);
    final span = created - min(seed.lastTouchDaysAgo, created);
    for (var i = 0; i < touches; i++) {
      final days = created - (span * (i + 1)) ~/ touches;
      final kind = _touchKinds[random.nextInt(_touchKinds.length)];
      final notes = _notes[kind] ?? const [''];
      rows.add(
        _activity(
          kind,
          graph.daysAgo(days, hour: 10 + random.nextInt(7), minute: 5),
          owner,
          description: notes[random.nextInt(notes.length)],
          minutes: switch (kind) {
            'Call' => 2 + random.nextInt(12),
            'Visit' => 25 + random.nextInt(50),
            'Meeting' => 30 + random.nextInt(60),
            _ => null,
          },
          outcome: kind == 'Call' ? 'Answered' : null,
        ),
      );
    }
    if (seed.stageId > 1) {
      rows.add(
        _activity(
          'StageChange',
          graph.daysAgo(_stageDays, hour: 17),
          owner,
          stage: leadStageJson(seed.stageId, null),
        ),
      );
    }
    if (_hasQuotation || (seed.stageId == 3 && seed.id.isEven)) {
      rows.add(
        _activity(
          'Quotation',
          graph.daysAgo(1 + seed.id % 5, hour: 15),
          owner,
          reference: 'Q-${(seed.id + 30).toString().padLeft(4, '0')}',
          amount: (seed.value * 0.9).round(),
          channel: seed.id.isEven ? 'WhatsApp' : 'Email',
          viewed: seed.id % 3 != 0,
        ),
      );
    }
    return rows;
  }

  Map<String, dynamic> _activity(
    String kind,
    DateTime at,
    String actor, {
    String? description,
    int? minutes,
    String? outcome,
    Map<String, dynamic>? stage,
    String? reference,
    int? amount,
    String? channel,
    bool viewed = false,
  }) => {
    'LeadId': seed.id,
    'Kind': kind,
    'OccurredOn': jsonUtc(at),
    'ActorName': actor,
    'Description': description,
    'DurationMinutes': minutes,
    'ActivityOutcome': outcome,
    'Stage': stage,
    'Reference': reference,
    'Amount': amount,
    'Channel': channel,
    'Viewed': viewed ? true : null,
  }..removeWhere((_, v) => v == null);

  static const _taskKinds = ['Call', 'Visit', 'Call', 'WhatsApp', 'Meeting'];

  static const _taskTitles = {
    'Call': [
      'Call about the quotation',
      'কোটেশন নিয়ে কল',
      'Confirm inverter size',
    ],
    'Visit': [
      'Site survey visit',
      'ছাদের মাপ নিতে ভিজিট',
      'Show panel samples',
    ],
    'WhatsApp': [
      'Send panel brochure',
      'প্রাইস লিস্ট পাঠান',
      'Share Savar project photos',
    ],
    'Meeting': ['Meeting with the MD', 'টেকনিক্যাল মিটিং', 'Final price talk'],
  };

  static const _touchKinds = ['Call', 'Call', 'WhatsApp', 'Visit', 'Note'];

  static const _notes = {
    'Call': [
      'Interested in price, asked for a quotation',
      'দাম নিয়ে আগ্রহী, কোটেশন চেয়েছেন',
      'Asked how long a 5kW battery backup lasts',
      'ছাদের মাপ পাঠাবেন বলেছেন',
      'MD will decide next week',
      'বাজেট ৳ ৩ লাখের মধ্যে, কিস্তিতে দিতে চান',
    ],
    'WhatsApp': [
      'Sent panel brochure and price list',
      'ব্রোশিওর পাঠানো হয়েছে',
      'Shared photos of the Savar installation',
    ],
    'Visit': [
      'Samples shown',
      'Site survey done, roof about 2,400 sft',
      'ফ্যাক্টরির লোড চেক করা হয়েছে',
      'Met the purchase manager at the office',
    ],
    'Note': [
      'Prefers tier-1 mono panels',
      'Payment in two parts, 60% advance',
      'জেনারেটরের তেলের খরচ কমাতে চান',
      'Competitor quoted ৳ 15,800 per 550W panel',
    ],
  };

  static const _comments = [
    'Wants 12 rooftop panels with net metering',
    'ছাদে ১২টা প্যানেল, নেট মিটারিং চান',
    'Three shifts, needs battery backup at night',
    'Load shedding 4–5 hours a day in the area',
    'অফিসের জন্য ৫ কিলোওয়াট সিস্টেম',
  ];

  static const _lostNotes = [
    'Went with a cheaper Chinese brand',
    'বাজেট পরের বছর',
    'No reply after three calls',
  ];
}
