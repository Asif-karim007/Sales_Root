import 'package:collection/collection.dart';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// The id of the seeded workspace owner.
int ownerIdOf(SeedGraph graph) =>
    graph.members.firstWhereOrNull((m) => m.role == WorkspaceRole.owner)?.id ??
    SeedGraph.meId;

/// The member's manager, or the owner when the seeded one isn't in this
/// workspace.
int? managerIdOf(SeedGraph graph, SeedMember member) {
  final managerId = member.managerId;
  if (managerId == null || member.role == WorkspaceRole.owner) return null;
  final exists = graph.members.any((m) => m.id == managerId);
  return exists ? managerId : ownerIdOf(graph);
}

List<Map<String, dynamic>> chatThreadFixtures(SeedGraph graph) =>
    _ChatSeed(graph).threads;

List<Map<String, dynamic>> chatMessageFixtures(SeedGraph graph) =>
    _ChatSeed(graph).messages;

/// The name the workspace-wide group carries.
String everyoneGroupTitle(SeedGraph graph) => switch (graph.workspaceId) {
  200 => 'Dhaka Sales',
  300 => 'Nexzen Partners',
  _ => 'Team',
};

/// Teammates' answers when the fake server plays the other side.
const List<String> chatReplies = [
  'ঠিক আছে ভাই, দেখছি।',
  'Ok, noted 👍',
  'জি, একটু পরে call দিচ্ছি।',
  'Customer এর সাথে কথা বলে জানাচ্ছি।',
  'আচ্ছা, আজকের মধ্যেই করে দিব।',
  'Thanks! Quotation টা আমাকেও forward করো।',
  'হ্যাঁ, stock আছে। Warehouse এ confirm করেছি।',
  'Meeting এর পরে details পাঠাচ্ছি।',
  'Visit শেষ করে update দিব, ইনশাআল্লাহ।',
  'ঠিক আছে, কাল সকালে প্রথমেই এটা ধরব।',
];

const List<(String, String)> _managerTalk = [
  (
    'Bhai, আজ Mirpur এ 3টা visit শেষ। Report দিয়ে দিচ্ছি।',
    'ঠিক আছে, ভালো কাজ।',
  ),
  (
    'Teesta Pharma এর 10kW quotation কি আজকেই যাবে?',
    'হ্যাঁ, বিকেল 4টার মধ্যে পাঠাও।',
  ),
  (
    'Customer installation date পিছাতে চাইছে, next week করা যাবে?',
    'Team এর schedule দেখে জানাচ্ছি।',
  ),
  ('আজ একটু দেরি হবে, জ্যামে আটকে আছি।', 'Ok, সাবধানে এসো।'),
  (
    'Lithium battery 10kWh এর dealer price টা কত?',
    '৳ 1,92,000 — price list এ update করা আছে।',
  ),
  ('Lead টা Won mark করে দিলাম 🎉', 'দারুণ! Invoice টা আজ করে ফেলো।'),
  ('Expense bill জমা দিয়েছি, approve করে দিয়েন।', 'দেখছি, আজকেই করে দিব।'),
];

class _ChatSeed {
  _ChatSeed(this.graph) {
    _build();
  }

  final SeedGraph graph;
  final threads = <Map<String, dynamic>>[];
  final messages = <Map<String, dynamic>>[];
  int _messageId = 0;

  static const me = SeedGraph.meId;

  bool _has(int id) => graph.members.any((m) => m.id == id);

  int? _managerOf(int id) {
    if (!_has(id)) return null;
    return managerIdOf(graph, graph.member(id));
  }

  DateTime _today(int minutesAgo) =>
      graph.anchor.subtract(Duration(minutes: minutesAgo));

  DateTime _day(int daysAgo, int hour, int minute) =>
      graph.daysAgo(daysAgo, hour: hour, minute: minute);

  int? _thread({
    required String kind,
    required List<int> people,
    required int createdDaysAgo,
    String title = '',
    bool everyone = false,
    int? adminId,
    int? leadId,
  }) {
    final present = people.where(_has).toSet().toList();
    if (present.length < 2) return null;
    final id = threads.length + 1;
    threads.add(
      {
        'Id': id,
        'Kind': kind,
        'Title': title,
        'IsEveryone': everyone,
        'ParticipantIds': present,
        'AdminId': adminId != null && _has(adminId) ? adminId : present.first,
        'LeadId': leadId,
        'CreatedAt': jsonUtc(_day(createdDaysAgo, 10, 0)),
        'Notifications': true,
        'AutoDownload': false,
        'LastReadId': 0,
      }..removeWhere((_, value) => value == null),
    );
    return id;
  }

  void _say(
    int? threadId,
    int sender,
    String text,
    DateTime at, {
    Map<String, dynamic>? attachment,
  }) {
    if (threadId == null || !_has(sender)) return;
    final thread = threads[threadId - 1];
    if (!(thread['ParticipantIds'] as List).contains(sender)) return;
    _messageId++;
    messages.add({
      'Id': _messageId,
      'ThreadId': threadId,
      'SenderId': sender,
      'Text': text,
      'SentAt': jsonUtc(at),
      'Status': 'Read',
      'Attachment': ?attachment,
    });
  }

  /// Marks everything up to now as read by me.
  void _readAll(int? threadId) {
    if (threadId == null) return;
    threads[threadId - 1]['LastReadId'] = _messageId;
  }

  void _build() {
    if (graph.members.length < 2) return;
    final owner = ownerIdOf(graph);
    final leads = graph.members
        .where((m) => m.role == WorkspaceRole.teamLead)
        .map((m) => m.id)
        .toList();
    final north = leads.isEmpty ? owner : leads.first;
    final south = leads.length > 1 ? leads[1] : owner;
    _everyone(owner, north, south);
    _team(north, 'Dhaka North team', mine: true);
    _team(south, 'Dhaka South team', mine: false);
    _groups(owner, north, south);
    _leadThreads(north, owner);
    _directs(owner, north);
  }

  void _everyone(int owner, int north, int south) {
    final active = graph.members.map((m) => m.id).toList();
    final id = _thread(
      kind: 'Group',
      title: everyoneGroupTitle(graph),
      everyone: true,
      people: active,
      adminId: owner,
      createdDaysAgo: 210,
    );
    _say(
      id,
      owner,
      'সবাইকে শুভ সকাল। এই মাসের target ৳ 1.2 crore — সবাই নিজের pipeline update করে রাখবেন।',
      _day(3, 9, 12),
    );
    _say(
      id,
      north,
      'জি ভাই, Dhaka North এর list আজকেই দিচ্ছি।',
      _day(3, 9, 30),
    );
    _say(
      id,
      south,
      'Meghna Group এর 50kW rooftop survey কাল সকালে। কেউ Savar side এ থাকলে জানাবেন।',
      _day(2, 17, 5),
    );
    _say(id, 10, 'আমি Savar এ আছি, join করতে পারব।', _day(2, 17, 22));
    _say(
      id,
      owner,
      'Delta Power এর order confirm — 8kW hybrid inverter ×3। Congrats Rafiq team 👏',
      _day(1, 12, 40),
    );
    _say(id, 5, 'Alhamdulillah! Warehouse এ IV-8K কয়টা আছে?', _day(1, 12, 52));
    _say(id, north, '6টা আছে, আরো 10টা আসছে বৃহস্পতিবার।', _day(1, 13, 5));
    _say(
      id,
      north,
      'সবাই, কাল সকাল 9:30 অফিসে meeting। মাসের target নিয়ে কথা হবে।',
      _today(190),
    );
    _say(id, me, 'ঠিক আছে ভাই', _today(188));
    _say(
      id,
      5,
      'ডেল্টা পাওয়ারের সাইটের ছবি',
      _today(155),
      attachment: {
        'Kind': 'Photo',
        'Title': 'Delta_Power_site.jpg',
        'SizeBytes': 846000,
      },
    );
    _say(id, north, '@Karim কোটেশন Q-0043 কি গেছে?', _today(125));
    _say(id, me, 'হ্যাঁ, WhatsApp এ পাঠিয়েছি। Link: Q-0043', _today(123));
    _readAll(id);
    _say(
      id,
      7,
      'আজ বিকেলে Uttara তে 2টা visit, কেউ brochure এর hard copy দিতে পারবেন?',
      _today(60),
    );
    _say(id, north, 'Front desk এ রাখা আছে, নিয়ে যেও।', _today(42));
    _say(
      id,
      south,
      'Collection update: Jamuna Electronics থেকে ৳ 1,80,000 এর cheque পেয়েছি।',
      _today(15),
    );
  }

  void _team(int leadId, String title, {required bool mine}) {
    final reports = graph.members
        .where((m) => _managerOf(m.id) == leadId)
        .map((m) => m.id)
        .where((id) => mine || id != me)
        .toList();
    final id = _thread(
      kind: 'Group',
      title: title,
      people: [leadId, ...reports],
      adminId: leadId,
      createdDaysAgo: 150,
    );
    if (reports.isEmpty) return;
    final first = reports.first;
    final second = reports.length > 1 ? reports[1] : first;
    _say(
      id,
      leadId,
      'আগামী সপ্তাহের visit plan শুক্রবারের মধ্যে দিয়ে দিও।',
      _day(1, 18, 10),
    );
    _say(id, second, 'Mirpur আর Pallabi area আমি নিচ্ছি।', _day(1, 18, 25));
    _say(id, leadId, 'Karim Textiles এর follow-up কে করছে?', _today(320));
    _say(id, first, 'আমি ভাই, আজ বিকেলে call দিব।', _today(318));
    _say(
      id,
      5,
      'ছবি পাঠালাম',
      _today(150),
      attachment: {
        'Kind': 'Photo',
        'Title': 'Shapla_Garments_roof.jpg',
        'SizeBytes': 1210000,
      },
    );
    _readAll(id);
  }

  void _groups(int owner, int north, int south) {
    final tech = _thread(
      kind: 'Group',
      title: 'Inverter tech support',
      people: [owner, north, south, me, 12],
      adminId: owner,
      createdDaysAgo: 90,
    );
    _say(
      tech,
      12,
      'Hybrid 5kW এ grid fail হলে switchover 10ms এর কম তো?',
      _day(5, 15, 0),
    );
    _say(
      tech,
      owner,
      'হ্যাঁ, UPS mode এ 10ms। Customer কে datasheet পাঠিয়ে দাও।',
      _day(5, 15, 18),
    );
    _say(
      tech,
      me,
      'Bashundhara site এ battery error E-04 দেখাচ্ছে, কেউ জানেন?',
      _day(4, 11, 40),
    );
    _say(
      tech,
      south,
      'E-04 মানে low SOC — rack এর breaker টা check করতে বলো।',
      _day(4, 11, 55),
    );
    _readAll(tech);

    final collection = _thread(
      kind: 'Group',
      title: 'Collection follow-up',
      people: [owner, north, south],
      adminId: owner,
      createdDaysAgo: 60,
    );
    _say(
      collection,
      owner,
      'এই সপ্তাহে ৳ 14 lakh due — কে কোনটা ধরছে আজকের মধ্যে জানাও।',
      _day(2, 10, 5),
    );
    _say(
      collection,
      north,
      'Karim Textiles আর Rahim Enterprise আমার team দেখছে।',
      _day(2, 10, 20),
    );
    _say(
      collection,
      south,
      'Jamuna Electronics এর cheque আজ পেয়েছি।',
      _today(14),
    );

    final rooftop = _thread(
      kind: 'Group',
      title: 'Rooftop survey team',
      people: [me, 5, 9, 10],
      adminId: me,
      createdDaysAgo: 20,
    );
    _say(
      rooftop,
      me,
      'Shapla Garments এর roof area মেপে নিও, approx 4,000 sqft শুনেছি।',
      _day(6, 10, 30),
    );
    _say(
      rooftop,
      9,
      'মেপেছি — 3,850 sqft, south facing. 60kW পর্যন্ত বসানো যাবে।',
      _day(6, 16, 45),
    );
    _readAll(rooftop);
  }

  void _leadThreads(int north, int owner) {
    final mine = graph.leadsOf(me).take(3).toList();
    for (var i = 0; i < mine.length; i++) {
      final lead = mine[i];
      final id = _thread(
        kind: 'Lead',
        people: [me, north, if (i == 1) owner],
        leadId: lead.id,
        createdDaysAgo: 12 - i * 3,
      );
      switch (i) {
        case 0:
          _say(id, me, 'ওরা 5% ছাড় চাইছে। দিতে পারি?', _day(1, 11, 20));
          _say(
            id,
            north,
            '3% পর্যন্ত দাও। বেশি হলে আমাকে বলো।',
            _day(1, 11, 24),
          );
          _say(
            id,
            me,
            'কোটেশন v2 পাঠিয়েছি 3% দিয়ে',
            _day(1, 11, 50),
            attachment: {
              'Kind': 'Quotation',
              'Title': 'Q-0042 v2',
              'RefId': 42,
              'LeadId': lead.id,
              'Amount': (lead.value * 0.97).round(),
            },
          );
        case 1:
          _say(
            id,
            me,
            'Site survey শেষ, 8kW hybrid + 10kWh battery suggest করছি।',
            _day(3, 16, 0),
          );
          _say(
            id,
            owner,
            'Good. Installation সহ package price দাও, AMC optional রাখো।',
            _day(3, 16, 30),
          );
        default:
          _say(
            id,
            north,
            'Purchase manager এর সাথে meeting কবে?',
            _day(2, 9, 45),
          );
          _say(
            id,
            me,
            'বৃহস্পতিবার 3টায়, brochure নিয়ে যাব।',
            _day(2, 10, 2),
          );
      }
      _readAll(id);
    }
    final others = graph.leads.where((l) => l.ownerId == 6).take(1);
    for (final lead in others) {
      final id = _thread(
        kind: 'Lead',
        people: [6, _managerOf(6) ?? owner],
        leadId: lead.id,
        createdDaysAgo: 4,
      );
      _say(
        id,
        6,
        'Customer budget কমাতে বলছে, 450W panel দিয়ে করি?',
        _day(1, 14, 0),
      );
      _say(
        id,
        _managerOf(6) ?? owner,
        'ঠিক আছে, দুইটা option দিয়েই quotation বানাও।',
        _day(1, 14, 20),
      );
      _say(id, 6, 'Ok bhai.', _day(1, 14, 22));
    }
  }

  void _directs(int owner, int north) {
    final rumpa = _thread(kind: 'Direct', people: [me, 4], createdDaysAgo: 80);
    _say(rumpa, 4, 'ডেল্টার স্যাম্পল কি আছে?', _day(1, 17, 30));
    _say(rumpa, me, 'আছে, অফিসে। কাল নিয়ে যাব।', _day(1, 17, 42));
    _readAll(rumpa);
    _say(
      rumpa,
      4,
      'আজ 14:30 এ visit। Route পাঠালাম।',
      _today(95),
      attachment: {
        'Kind': 'Location',
        'Title': 'Mirpur 10 → Pallabi → Kalshi',
        'Lat': 23.8069,
        'Lng': 90.3687,
      },
    );

    final lead = _thread(
      kind: 'Direct',
      people: [me, north],
      createdDaysAgo: 120,
    );
    _say(
      lead,
      north,
      'Karim, Rahim Agro এর পুরনো due টা একটু follow-up করো।',
      _day(4, 12, 0),
    );
    _say(lead, me, 'জি ভাই, আজকেই call দিচ্ছি।', _day(4, 12, 6));
    _say(lead, north, 'Okay, thanks', _day(4, 12, 9));
    _readAll(lead);

    final boss = _thread(
      kind: 'Direct',
      people: [me, owner],
      createdDaysAgo: 100,
    );
    _say(
      boss,
      owner,
      'গত মাসের collection ভালো হয়েছে, keep it up।',
      _day(6, 19, 0),
    );
    _say(boss, me, 'ধন্যবাদ স্যার!', _day(6, 19, 15));
    _readAll(boss);

    final pair = _thread(kind: 'Direct', people: [4, 5], createdDaysAgo: 40);
    const banter = [
      (4, 'আজ Gulshan এর meeting এ তুমি আসছো?'),
      (5, 'হ্যাঁ, 12টার মধ্যে পৌঁছাব।'),
      (4, 'Brochure গুলো নিয়ে এসো, আমার কাছে শেষ।'),
      (5, 'ঠিক আছে, 20টা নিচ্ছি।'),
      (4, 'Client নতুন 5kW kit এর price জানতে চাইবে।'),
      (5, 'Price list v3 টা phone এ রাখো।'),
    ];
    for (var i = 0; i < banter.length; i++) {
      _say(pair, banter[i].$1, banter[i].$2, _today(240 - i * 25));
    }

    final sync = _thread(
      kind: 'Direct',
      people: [6, north],
      createdDaysAgo: 30,
    );
    _say(
      sync,
      6,
      'Bhai, আমার phone এ app 2 দিন ধরে sync হচ্ছে না।',
      _day(1, 10, 15),
    );
    _say(
      sync,
      north,
      'More → Sync এ গিয়ে একবার try করো, না হলে আমাকে call দিও।',
      _day(1, 10, 40),
    );

    var turn = 0;
    for (final member in graph.members) {
      final managerId = _managerOf(member.id);
      if (member.id == me || member.id <= 6 || managerId == null) continue;
      final id = _thread(
        kind: 'Direct',
        people: [member.id, managerId],
        createdDaysAgo: 60,
      );
      final (ask, answer) = _managerTalk[turn % _managerTalk.length];
      final daysAgo = turn % 5;
      _say(id, member.id, ask, _day(daysAgo, 9 + turn % 8, 10));
      _say(id, managerId, answer, _day(daysAgo, 9 + turn % 8, 34));
      turn++;
    }
  }
}
