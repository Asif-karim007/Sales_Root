import 'dart:math';

import 'package:salesroot/core/workspace/workspace.dart';

/// The shared fake world every feature's fixtures build on, so a lead's
/// company, contact, owner and products agree across screens.
class SeedGraph {
  SeedGraph._({
    required this.workspaceId,
    required this.members,
    required this.companies,
    required this.contacts,
    required this.leads,
    required this.products,
    required this.anchor,
  });

  final int workspaceId;
  final List<SeedMember> members;
  final List<SeedCompany> companies;
  final List<SeedContact> contacts;
  final List<SeedLead> leads;
  final List<SeedProduct> products;

  /// "Now" at seed time; fixtures place dates relative to it.
  final DateTime anchor;

  static const int meId = 1;

  SeedMember get me => members.firstWhere((m) => m.id == meId);

  SeedMember member(int id) => members.firstWhere((m) => m.id == id);
  SeedCompany company(int id) => companies.firstWhere((c) => c.id == id);
  SeedContact contact(int id) => contacts.firstWhere((c) => c.id == id);
  SeedLead lead(int id) => leads.firstWhere((l) => l.id == id);
  SeedProduct product(int id) => products.firstWhere((p) => p.id == id);

  List<SeedContact> contactsOf(int companyId) =>
      contacts.where((c) => c.companyId == companyId).toList();

  List<SeedLead> leadsOf(int ownerId) =>
      leads.where((l) => l.ownerId == ownerId).toList();

  /// A deterministic random source for a fixture, so reseeding is stable.
  Random random(String salt) => Random(Object.hash(workspaceId, salt));

  DateTime daysAgo(int days, {int hour = 10, int minute = 0}) {
    final day = anchor.subtract(Duration(days: days));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  DateTime daysAhead(int days, {int hour = 10, int minute = 0}) =>
      daysAgo(-days, hour: hour, minute: minute);

  factory SeedGraph.build({
    required int workspaceId,
    required WorkspaceKind kind,
    required int memberCount,
    required int leadCount,
    DateTime? now,
  }) {
    final random = Random(workspaceId * 7919 + 17);
    final anchor = now ?? DateTime.now();
    final members = _members(kind, memberCount);
    final companies = _companies(random);
    final contacts = _contacts(random, companies);
    final leads = _leads(random, leadCount, members, companies, contacts);
    return SeedGraph._(
      workspaceId: workspaceId,
      members: members,
      companies: companies,
      contacts: contacts,
      leads: leads,
      products: _products,
      anchor: anchor,
    );
  }

  static List<SeedMember> _members(WorkspaceKind kind, int count) {
    if (kind == WorkspaceKind.personal) {
      return [_memberAt(0, WorkspaceRole.owner, null)];
    }
    return [
      for (var i = 0; i < count && i < _people.length; i++)
        _memberAt(
          i,
          switch (i) {
            1 => WorkspaceRole.owner,
            2 || 7 => WorkspaceRole.teamLead,
            _ => WorkspaceRole.member,
          },
          switch (i) {
            1 => null,
            2 || 7 => 2,
            _ => i.isEven ? 3 : 8,
          },
        ),
    ];
  }

  static SeedMember _memberAt(int index, WorkspaceRole role, int? managerId) {
    final person = _people[index];
    return SeedMember(
      id: index + 1,
      name: person.$1,
      nameBn: person.$2,
      phone: '+8801${710000000 + index * 1234567 % 89999999}',
      role: role,
      managerId: managerId,
      designation: switch (role) {
        WorkspaceRole.owner => 'Managing Director',
        WorkspaceRole.teamLead => 'Sales Manager',
        WorkspaceRole.member => 'Sales Executive',
      },
    );
  }

  static List<SeedCompany> _companies(Random random) => [
    for (var i = 0; i < _companyNames.length; i++)
      SeedCompany(
        id: i + 1,
        name: _companyNames[i],
        industry: _industries[random.nextInt(_industries.length)],
        area: _areas[i % _areas.length],
        phone: _phone(random),
        website: i % 3 == 0
            ? 'www.${_companyNames[i].toLowerCase().replaceAll(RegExp('[^a-z]'), '')}.com.bd'
            : null,
      ),
  ];

  static List<SeedContact> _contacts(
    Random random,
    List<SeedCompany> companies,
  ) {
    final contacts = <SeedContact>[];
    var id = 1;
    for (final company in companies) {
      final count = 1 + random.nextInt(3);
      for (var i = 0; i < count; i++) {
        final person = _contactPeople[(id * 7) % _contactPeople.length];
        contacts.add(
          SeedContact(
            id: id,
            companyId: company.id,
            name: person,
            designation: _designations[random.nextInt(_designations.length)],
            phone: _phone(random),
            email: i == 0
                ? '${person.split(' ').last.toLowerCase()}@${company.name.split(' ').first.toLowerCase()}.com'
                : null,
            isPrimary: i == 0,
          ),
        );
        id++;
      }
    }
    return contacts;
  }

  static List<SeedLead> _leads(
    Random random,
    int count,
    List<SeedMember> members,
    List<SeedCompany> companies,
    List<SeedContact> contacts,
  ) {
    final sellers = members
        .where((m) => m.role != WorkspaceRole.owner || members.length == 1)
        .toList();
    return [
      for (var i = 0; i < count; i++)
        _lead(i, random, sellers, companies, contacts),
    ];
  }

  static SeedLead _lead(
    int index,
    Random random,
    List<SeedMember> sellers,
    List<SeedCompany> companies,
    List<SeedContact> contacts,
  ) {
    final company = companies[index % companies.length];
    final companyContacts = contacts
        .where((c) => c.companyId == company.id)
        .toList();
    final stage = _stageFor(random.nextInt(100));
    final owner = index < 12
        ? sellers.firstWhere((m) => m.id == meId, orElse: () => sellers.first)
        : sellers[random.nextInt(sellers.length)];
    return SeedLead(
      id: index + 1,
      title: index < companies.length
          ? company.name
          : '${company.name} — ${_dealKinds[random.nextInt(_dealKinds.length)]}',
      companyId: company.id,
      contactId: companyContacts[random.nextInt(companyContacts.length)].id,
      ownerId: owner.id,
      stageId: stage,
      value: (random.nextInt(58) + 2) * 10000,
      source: _sources[random.nextInt(_sources.length)],
      createdDaysAgo: random.nextInt(120),
      lastTouchDaysAgo: random.nextInt(10),
      hot: random.nextInt(5) == 0,
    );
  }

  static int _stageFor(int roll) {
    if (roll < 28) return 1;
    if (roll < 50) return 2;
    if (roll < 68) return 3;
    if (roll < 80) return 4;
    if (roll < 92) return 5;
    return 6;
  }

  static String _phone(Random random) {
    const prefixes = ['13', '14', '15', '16', '17', '18', '19'];
    final body = 10000000 + random.nextInt(89999999);
    return '+880${prefixes[random.nextInt(prefixes.length)]}$body';
  }

  /// Default pipeline: id, English, Bangla, win probability.
  static const List<(int, String, String, int)> stages = [
    (1, 'To contact', 'যোগাযোগ বাকি', 10),
    (2, 'Contacted', 'যোগাযোগ হয়েছে', 25),
    (3, 'Interested', 'আগ্রহী', 65),
    (4, 'Quotation', 'কোটেশন', 40),
    (5, 'Won', 'জিতেছি', 100),
    (6, 'Lost', 'হারিয়েছি', 0),
  ];

  static const List<(String, String)> _people = [
    ('Karim Hossain', 'করিম হোসেন'),
    ('Mohammad Kamal', 'মোহাম্মদ কামাল'),
    ('Rafiqul Islam', 'রফিকুল ইসলাম'),
    ('Rumpa Sarker', 'রুম্পা সরকার'),
    ('Bushra Nowshin', 'বুশরা নওশিন'),
    ('Abdul Malek', 'আব্দুল মালেক'),
    ('Nasrin Akter', 'নাসরিন আক্তার'),
    ('Tanvir Ahmed', 'তানভীর আহমেদ'),
    ('Farhana Yasmin', 'ফারহানা ইয়াসমিন'),
    ('Masud Rana', 'মাসুদ রানা'),
    ('Shirin Sultana', 'শিরিন সুলতানা'),
    ('Arif Chowdhury', 'আরিফ চৌধুরী'),
    ('Mahmudul Hasan', 'মাহমুদুল হাসান'),
    ('Taslima Khatun', 'তাসলিমা খাতুন'),
    ('Imran Hossain', 'ইমরান হোসেন'),
    ('Mitu Das', 'মিতু দাস'),
    ('Pritom Saha', 'প্রীতম সাহা'),
    ('Anika Rahman', 'আনিকা রহমান'),
    ('Fahim Uddin', 'ফাহিম উদ্দিন'),
    ('Sharmin Akter', 'শারমিন আক্তার'),
    ('Kamrul Islam', 'কামরুল ইসলাম'),
    ('Liton Das', 'লিটন দাস'),
    ('Moushumi Roy', 'মৌসুমী রায়'),
    ('Habibur Rahman', 'হাবিবুর রহমান'),
    ('Selina Parvin', 'সেলিনা পারভীন'),
  ];

  static const List<String> _contactPeople = [
    'Md. Karim',
    'Sajib Hossain',
    'Rashed Khan',
    'Sumi Begum',
    'Jamal Uddin',
    'Nipa Akter',
    'Tuhin Mia',
    'Sabbir Hasan',
    'Rezaul Karim',
    'Ayesha Siddiqua',
    'Zahid Hasan',
    'Ruma Akter',
    'Faruk Ahmed',
    'Sohel Rana',
    'Lipi Khatun',
    'Nazmul Huda',
    'Joynal Abedin',
    'Shahana Begum',
    'Mizanur Rahman',
    'Kohinoor Akter',
    'Delwar Hossain',
    'Rokeya Sultana',
    'Abul Kalam',
    'Parvez Alam',
  ];

  static const List<String> _companyNames = [
    'Karim Textiles',
    'Delta Power',
    'Meghna Group',
    'Rahim Enterprise',
    'Masud Traders',
    'Jamal Store',
    'Padma Properties',
    'Rahim Agro',
    'Sabbir Traders',
    'City Pharma',
    'Green Agro',
    'New Light',
    'Bengal Steel',
    'Jamuna Electronics',
    'Surma Foods',
    'Karnaphuli Shipping',
    'Teesta Pharma',
    'Rupsha Ceramics',
    'Shapla Garments',
    'Dhaka Builders',
    'Sonar Bangla Rice Mill',
    'Unity Hardware',
    'Nabil Distribution',
    'Apex Furniture',
    'Royal Tiles',
    'City Medical Hall',
    'Star Electric',
    'Sunrise Paints',
    'Golden Harvest Feed',
    'Rangdhanu Printers',
    'Bismillah Motors',
    'Prime Pharmacy',
    'Ocean Fisheries',
    'Lalbagh Sweets',
    'Hatirjheel Cafe',
    'Mirpur Auto Parts',
    'Sylhet Tea Traders',
    'Rajshahi Mango House',
    'Khulna Jute Mills',
    'Comilla Bakery',
    'Banani Dental Care',
    'Gulshan Interiors',
    'Uttara Steel House',
    'Motijheel Stationers',
    'Savar Brick Field',
    'Narayanganj Knit',
    'Gazipur Poultry',
    'Tongi Plastics',
    'Bashundhara Electronics',
    'Mohakhali Pharma Depot',
    'Farmgate Mobile Center',
    'Dhanmondi Diagnostics',
    'Badda Glass House',
    'Rampura Furniture',
    'Keraniganj Dyeing',
    'Ashulia Packaging',
    'Mohammadpur Tailors',
    'Shyamoli Opticals',
    'Kawran Bazar Traders',
    'New Market Fabrics',
  ];

  /// Dhaka areas with a representative coordinate.
  static const List<SeedArea> _areas = [
    SeedArea('Mirpur', 'মিরপুর', 23.8223, 90.3654),
    SeedArea('Banani', 'বনানী', 23.7937, 90.4066),
    SeedArea('Motijheel', 'মতিঝিল', 23.7330, 90.4172),
    SeedArea('Gulshan', 'গুলশান', 23.7925, 90.4078),
    SeedArea('Dhanmondi', 'ধানমন্ডি', 23.7461, 90.3742),
    SeedArea('Uttara', 'উত্তরা', 23.8759, 90.3795),
    SeedArea('Mohakhali', 'মহাখালী', 23.7778, 90.4057),
    SeedArea('Tejgaon', 'তেজগাঁও', 23.7590, 90.3926),
    SeedArea('Badda', 'বাড্ডা', 23.7806, 90.4265),
    SeedArea('Bashundhara', 'বসুন্ধরা', 23.8193, 90.4526),
    SeedArea('Farmgate', 'ফার্মগেট', 23.7561, 90.3872),
    SeedArea('Kawran Bazar', 'কারওয়ান বাজার', 23.7510, 90.3935),
    SeedArea('Shyamoli', 'শ্যামলী', 23.7746, 90.3657),
    SeedArea('Mohammadpur', 'মোহাম্মদপুর', 23.7662, 90.3589),
    SeedArea('Rampura', 'রামপুরা', 23.7612, 90.4210),
    SeedArea('Savar', 'সাভার', 23.8583, 90.2667),
    SeedArea('Gazipur', 'গাজীপুর', 23.9999, 90.4203),
    SeedArea('Narayanganj', 'নারায়ণগঞ্জ', 23.6238, 90.5000),
    SeedArea('Tongi', 'টঙ্গী', 23.8915, 90.4023),
    SeedArea('Keraniganj', 'কেরানীগঞ্জ', 23.6980, 90.3460),
  ];

  static List<SeedArea> get areas => _areas;

  static const List<String> _industries = [
    'Textile',
    'Electronics',
    'Pharma',
    'Food',
    'Construction',
    'Retail',
    'Agro',
    'Furniture',
    'Healthcare',
    'Printing',
  ];

  static const List<String> _designations = [
    'Purchase Manager',
    'Owner',
    'Managing Director',
    'Admin Officer',
    'Accounts Manager',
    'Factory Manager',
    'Procurement Lead',
  ];

  static const List<String> _sources = [
    'Facebook',
    'Referral',
    'Walk-in',
    'Phone call',
    'Visit',
    'Website',
    'WhatsApp',
    'Visiting card',
  ];

  static List<String> get sources => _sources;

  static const List<String> _dealKinds = [
    'rooftop solar',
    'backup inverter',
    'factory expansion',
    'annual maintenance',
    'battery upgrade',
  ];

  static const List<SeedProduct> _products = [
    SeedProduct(
      1,
      'SP-550',
      'Solar panel 550W',
      'Solar',
      'piece',
      18500,
      17200,
    ),
    SeedProduct(
      2,
      'SP-450',
      'Solar panel 450W',
      'Solar',
      'piece',
      15200,
      14000,
    ),
    SeedProduct(
      3,
      'SP-330',
      'Solar panel 330W',
      'Solar',
      'piece',
      11800,
      10900,
    ),
    SeedProduct(4, 'SP-200', 'Solar panel 200W', 'Solar', 'piece', 7600, 7000),
    SeedProduct(5, 'SP-100', 'Solar panel 100W', 'Solar', 'piece', 4200, 3900),
    SeedProduct(
      6,
      'IV-3K',
      'Hybrid inverter 3kW',
      'Inverters',
      'piece',
      48000,
      44500,
    ),
    SeedProduct(
      7,
      'IV-5K',
      'Hybrid inverter 5kW',
      'Inverters',
      'piece',
      68000,
      63000,
    ),
    SeedProduct(
      8,
      'IV-8K',
      'Hybrid inverter 8kW',
      'Inverters',
      'piece',
      96000,
      89000,
    ),
    SeedProduct(
      9,
      'IV-10K',
      'On-grid inverter 10kW',
      'Inverters',
      'piece',
      115000,
      107000,
    ),
    SeedProduct(
      10,
      'IV-1K',
      'Home IPS 1kVA',
      'Inverters',
      'piece',
      16500,
      15200,
    ),
    SeedProduct(
      11,
      'BT-5',
      'Lithium battery 5kWh',
      'Batteries',
      'piece',
      110000,
      102000,
    ),
    SeedProduct(
      12,
      'BT-10',
      'Lithium battery 10kWh',
      'Batteries',
      'piece',
      205000,
      192000,
    ),
    SeedProduct(
      13,
      'BT-200',
      'Tubular battery 200Ah',
      'Batteries',
      'piece',
      24500,
      22800,
    ),
    SeedProduct(
      14,
      'BT-150',
      'Tubular battery 150Ah',
      'Batteries',
      'piece',
      19800,
      18400,
    ),
    SeedProduct(
      15,
      'CB-4',
      'Solar DC cable 4mm²',
      'Accessories',
      'metre',
      120,
      105,
    ),
    SeedProduct(
      16,
      'CB-6',
      'Solar DC cable 6mm²',
      'Accessories',
      'metre',
      165,
      148,
    ),
    SeedProduct(
      17,
      'MC-4',
      'MC4 connector pair',
      'Accessories',
      'pair',
      350,
      300,
    ),
    SeedProduct(
      18,
      'MS-R',
      'Rooftop mounting structure',
      'Accessories',
      'per kW',
      6500,
      6000,
    ),
    SeedProduct(
      19,
      'MS-G',
      'Ground mounting structure',
      'Accessories',
      'per kW',
      8200,
      7600,
    ),
    SeedProduct(
      20,
      'CC-60',
      'MPPT charge controller 60A',
      'Accessories',
      'piece',
      14500,
      13400,
    ),
    SeedProduct(
      21,
      'DB-1',
      'DC combiner box',
      'Accessories',
      'piece',
      9800,
      9000,
    ),
    SeedProduct(
      22,
      'SA-1',
      'Surge arrester',
      'Accessories',
      'piece',
      2600,
      2300,
    ),
    SeedProduct(
      23,
      'EM-1',
      'Smart energy meter',
      'Accessories',
      'piece',
      7400,
      6800,
    ),
    SeedProduct(
      24,
      'WF-1',
      'Wi-Fi monitoring dongle',
      'Accessories',
      'piece',
      3500,
      3100,
    ),
    SeedProduct(
      25,
      'SL-60',
      'Solar street light 60W',
      'Lighting',
      'piece',
      21000,
      19500,
    ),
    SeedProduct(
      26,
      'SL-30',
      'Solar street light 30W',
      'Lighting',
      'piece',
      13500,
      12400,
    ),
    SeedProduct(
      27,
      'FL-100',
      'LED flood light 100W',
      'Lighting',
      'piece',
      3900,
      3500,
    ),
    SeedProduct(
      28,
      'PM-1',
      'Solar water pump 1HP',
      'Pumps',
      'piece',
      58000,
      54000,
    ),
    SeedProduct(
      29,
      'PM-2',
      'Solar water pump 2HP',
      'Pumps',
      'piece',
      86000,
      80000,
    ),
    SeedProduct(
      30,
      'SV-INS',
      'Installation service',
      'Services',
      'per kW',
      4000,
      4000,
    ),
    SeedProduct(31, 'SV-SUR', 'Site survey', 'Services', 'visit', 2500, 2500),
    SeedProduct(
      32,
      'SV-AMC',
      'Annual maintenance contract',
      'Services',
      'year',
      18000,
      18000,
    ),
    SeedProduct(
      33,
      'SV-CLN',
      'Panel cleaning',
      'Services',
      'visit',
      3000,
      3000,
    ),
    SeedProduct(
      34,
      'SV-NM',
      'Net metering paperwork',
      'Services',
      'job',
      15000,
      15000,
    ),
    SeedProduct(
      35,
      'SV-TRN',
      'Operator training',
      'Services',
      'day',
      6000,
      6000,
    ),
    SeedProduct(
      36,
      'SV-EXT',
      'Extended warranty 5 years',
      'Services',
      'job',
      22000,
      22000,
    ),
    SeedProduct(37, 'KT-1', 'Home solar kit 1kW', 'Solar', 'set', 98000, 91000),
    SeedProduct(
      38,
      'KT-3',
      'Home solar kit 3kW',
      'Solar',
      'set',
      265000,
      248000,
    ),
    SeedProduct(
      39,
      'KT-5',
      'Office solar kit 5kW',
      'Solar',
      'set',
      420000,
      395000,
    ),
    SeedProduct(
      40,
      'KT-10',
      'Factory solar kit 10kW',
      'Solar',
      'set',
      790000,
      745000,
    ),
    SeedProduct(41, 'BT-RK', 'Battery rack', 'Batteries', 'piece', 8500, 7800),
    SeedProduct(42, 'EA-1', 'Earthing kit', 'Accessories', 'set', 5200, 4800),
  ];
}

class SeedMember {
  const SeedMember({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.phone,
    required this.role,
    required this.managerId,
    required this.designation,
  });

  final int id;
  final String name;
  final String nameBn;
  final String phone;
  final WorkspaceRole role;
  final int? managerId;
  final String designation;
}

class SeedCompany {
  const SeedCompany({
    required this.id,
    required this.name,
    required this.industry,
    required this.area,
    required this.phone,
    this.website,
  });

  final int id;
  final String name;
  final String industry;
  final SeedArea area;
  final String phone;
  final String? website;
}

class SeedContact {
  const SeedContact({
    required this.id,
    required this.companyId,
    required this.name,
    required this.designation,
    required this.phone,
    required this.isPrimary,
    this.email,
  });

  final int id;
  final int companyId;
  final String name;
  final String designation;
  final String phone;
  final String? email;
  final bool isPrimary;
}

class SeedLead {
  const SeedLead({
    required this.id,
    required this.title,
    required this.companyId,
    required this.contactId,
    required this.ownerId,
    required this.stageId,
    required this.value,
    required this.source,
    required this.createdDaysAgo,
    required this.lastTouchDaysAgo,
    required this.hot,
  });

  final int id;
  final String title;
  final int companyId;
  final int contactId;
  final int ownerId;
  final int stageId;
  final int value;
  final String source;
  final int createdDaysAgo;
  final int lastTouchDaysAgo;
  final bool hot;

  bool get isOpen => stageId < 5;
}

class SeedProduct {
  const SeedProduct(
    this.id,
    this.code,
    this.name,
    this.category,
    this.unit,
    this.price,
    this.dealerPrice,
  );

  final int id;
  final String code;
  final String name;
  final String category;
  final String unit;
  final int price;
  final int dealerPrice;
}

class SeedArea {
  const SeedArea(this.name, this.nameBn, this.lat, this.lng);

  final String name;
  final String nameBn;
  final double lat;
  final double lng;
}
