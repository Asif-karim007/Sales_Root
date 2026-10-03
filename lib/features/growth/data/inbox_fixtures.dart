import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

const growthInboxTable = 'growth_inbox';

const solarForm = 'Solar home package – October';
const dealerForm = 'Dealer application';
const solarCampaign = 'SolarOct26';

/// New leads from Facebook forms, the website and WhatsApp, spread from a
/// few minutes to a few days old, in every inbox state.
List<Map<String, dynamic>> inboxFixtures(SeedGraph graph) {
  final members = graph.members;
  int at(int index) => members[index % members.length].id;
  String ago(int minutes) =>
      jsonUtc(graph.anchor.subtract(Duration(minutes: minutes))) ?? '';
  final company = graph.company(4);
  final contact = graph.contacts[5];

  Map<String, dynamic> facebook(
    int id,
    String name,
    String phone,
    String area,
    int minutes, {
    String form = solarForm,
    String? interest,
    List<Map<String, dynamic>> answers = const [],
  }) => {
    'Id': id,
    'Name': name,
    'Phone': phone,
    'Area': area,
    'Source': 'Facebook',
    'Status': 'New',
    'FormName': form,
    'Campaign': form == solarForm ? solarCampaign : null,
    'Interest': interest,
    'Answers': answers,
    'ConsentAt': ago(minutes),
    'ExternalId': 'l_${8823900000 + id * 7919}',
    'ReceivedAt': ago(minutes),
  };

  Map<String, dynamic> direct(
    int id,
    String source,
    String name,
    String phone,
    String area,
    int minutes,
    String interest, {
    String? email,
  }) => {
    'Id': id,
    'Name': name,
    'Phone': phone,
    'Email': email,
    'Area': area,
    'Source': source,
    'Status': 'New',
    'Interest': interest,
    'Answers': [
      if (source == 'Website') ...[
        _answer('Message', 'মেসেজ', interest),
        _answer('Page', 'পেজ', 'dhakasales.com/contact'),
      ],
    ],
    'ReceivedAt': ago(minutes),
  };

  Map<String, dynamic> handled(
    Map<String, dynamic> row, {
    required String status,
    int? assignedTo,
    String? rule,
    int? responded,
    String? reason,
  }) => {
    ...row,
    'Status': status,
    'AssignedToId': assignedTo,
    'AssignedByRule': rule,
    'RespondedMinutes': responded,
    'RejectReason': reason,
  };

  return [
    facebook(
      1,
      'Rahima Begum',
      '+8801912345678',
      'Uttara',
      4,
      interest: 'Solar home package · roof 800 sq ft',
      answers: [
        _answer('Roof size', 'ছাদের আকার', '800 sq ft'),
        _answer('Monthly bill', 'মাসিক বিল', '৳ 6,000–9,000'),
      ],
    ),
    direct(
      2,
      'Website',
      'Farhan Hossain',
      '+8801711458902',
      'Savar',
      12,
      'ডিলার হতে চাই, সাভার বাজারে ইলেকট্রিক দোকান আছে',
      email: 'farhan.savar@gmail.com',
    ),
    direct(
      3,
      'WhatsApp',
      'Nila Sikder',
      '+8801819224466',
      'Banani',
      18,
      'দাম জানতে চাই — 3kW hybrid system',
    ),
    facebook(
      4,
      company.name,
      company.phone,
      company.area.name,
      35,
      interest: 'Factory roof 5,000 sq ft, need a quotation',
      answers: [
        _answer('Roof size', 'ছাদের আকার', '5,000 sq ft'),
        _answer('Monthly bill', 'মাসিক বিল', '৳ 80,000+'),
      ],
    ),
    handled(
      facebook(
        5,
        'Saifur Rahman',
        '+8801556781234',
        'Mirpur',
        62,
        form: dealerForm,
        interest: 'Dealer application · Mirpur 10',
        answers: [
          _answer('Business name', 'ব্যবসার নাম', 'Rahman Electric House'),
          _answer('Experience', 'অভিজ্ঞতা', '6 years in IPS and batteries'),
        ],
      ),
      status: 'Assigned',
      assignedTo: at(3),
      rule: 'Dealer applications',
      responded: 7,
    ),
    direct(
      6,
      'Website',
      'Moushumi Akter',
      '+8801671120934',
      'Gulshan',
      7,
      'Office backup inverter 5kW lagbe, kalke call korben',
      email: 'moushumi@greenlinebd.com',
    ),
    facebook(
      7,
      'Jahid Hasan',
      '+8801819907711',
      'Uttara',
      26,
      interest: 'Solar home package · roof 1,200 sq ft',
      answers: [
        _answer('Roof size', 'ছাদের আকার', '1,200 sq ft'),
        _answer('Monthly bill', 'মাসিক বিল', '৳ 10,000–15,000'),
      ],
    ),
    direct(
      8,
      'WhatsApp',
      'Sharif Ahmed',
      '+8801911339902',
      'Tongi',
      2,
      'ফ্যাক্টরিতে 50kW সোলার লাগাতে চাই, কেউ সাইট ভিজিটে আসবেন?',
    ),
    handled(
      facebook(
        9,
        'Tania Islam',
        '+8801714556120',
        'Dhanmondi',
        96,
        form: dealerForm,
        interest: 'Dealer application · Dhanmondi',
        answers: [
          _answer('Business name', 'ব্যবসার নাম', 'Tania Solar Point'),
          _answer('Experience', 'অভিজ্ঞতা', 'New business'),
        ],
      ),
      status: 'Assigned',
      assignedTo: SeedGraph.meId,
      rule: 'Dealer applications',
      responded: 11,
    ),
    handled(
      direct(
        10,
        'Website',
        'Kabir Uddin',
        '+8801612009876',
        'Narayanganj',
        142,
        'Need quotation for 20 solar street lights (60W) for our union parishad road',
        email: 'kabir.ud@yahoo.com',
      ),
      status: 'Assigned',
      assignedTo: SeedGraph.meId,
      rule: 'Website enquiries',
      responded: 9,
    ),
    direct(
      11,
      'WhatsApp',
      contact.name,
      contact.phone,
      graph.company(contact.companyId).area.name,
      48,
      'Amader ager inverter e problem, service lagbe',
    ),
    facebook(
      12,
      'Arif Billah',
      '+8801815673420',
      'Keraniganj',
      10,
      interest: 'Solar home package · roof 600 sq ft',
      answers: [
        _answer('Roof size', 'ছাদের আকার', '600 sq ft'),
        _answer('Monthly bill', 'মাসিক বিল', '৳ 4,000–6,000'),
      ],
    ),
    direct(
      13,
      'Website',
      'Sumaiya Khan',
      '+8801731998844',
      'Bashundhara',
      31,
      'Rooftop solar for a duplex house, 2 floors. Net metering possible?',
      email: 'sumaiya.khan@outlook.com',
    ),
    handled(
      direct(
        14,
        'WhatsApp',
        'Polash Mia',
        '+8801309871244',
        'Gazipur',
        76,
        'সোলার পাম্প 2HP এর দাম কত?',
      ),
      status: 'Assigned',
      assignedTo: at(5),
      rule: 'Everything else',
      responded: 14,
    ),
    facebook(
      15,
      'Rokon Uddin',
      '+8801552340987',
      'Savar',
      185,
      form: dealerForm,
      interest: 'Dealer application · Savar EPZ',
      answers: [
        _answer('Business name', 'ব্যবসার নাম', 'Rokon Traders'),
        _answer('Experience', 'অভিজ্ঞতা', '3 years in electrical goods'),
      ],
    ),
    handled(
      facebook(16, 'Habib Ullah', '+8801716203344', 'Mohakhali', 1500),
      status: 'Accepted',
      assignedTo: at(3),
      rule: 'Solar ads',
      responded: 6,
    ),
    handled(
      direct(
        17,
        'Website',
        'Nusrat Jahan',
        '+8801819551200',
        'Uttara',
        1720,
        'AMC for existing 10kW plant',
        email: 'nusrat@uttaradental.com',
      ),
      status: 'Accepted',
      assignedTo: at(4),
      rule: 'Uttara & Mirpur',
      responded: 9,
    ),
    handled(
      direct(
        18,
        'WhatsApp',
        'Mamun Hossain',
        '+8801912776655',
        'Farmgate',
        2100,
        'IPS 1kVA দাম কত?',
      ),
      status: 'Accepted',
      assignedTo: SeedGraph.meId,
      responded: 4,
    ),
    handled(
      facebook(19, 'Selim Reza', '+8801558990011', 'Mirpur', 2600),
      status: 'Accepted',
      assignedTo: at(6),
      rule: 'Uttara & Mirpur',
      responded: 12,
    ),
    handled(
      facebook(
        20,
        'Shapla Akter',
        '+8801677445566',
        'Badda',
        3100,
        form: dealerForm,
      ),
      status: 'Accepted',
      assignedTo: at(2),
      rule: 'Dealer applications',
      responded: 10,
    ),
    handled(
      direct(
        21,
        'Website',
        'Tarek Aziz',
        '+8801714000231',
        'Tejgaon',
        3900,
        'Factory solar kit 10kW price with installation',
        email: 'tarek.aziz@bengalsteel.com.bd',
      ),
      status: 'Accepted',
      assignedTo: at(7),
      responded: 8,
    ),
    handled(
      facebook(22, 'Test Test', '+8801000000000', 'Mirpur', 900),
      status: 'Rejected',
      reason: 'Spam',
    ),
    handled(
      direct(
        23,
        'WhatsApp',
        'Unknown',
        '+8801311111111',
        'Rampura',
        1300,
        'hi',
      ),
      status: 'Rejected',
      reason: 'WrongNumber',
    ),
    handled(
      facebook(24, 'Abu Sayeed', '+8801815554433', 'Keraniganj', 2400),
      status: 'Rejected',
      reason: 'OutOfArea',
    ),
    handled(
      direct(
        25,
        'Website',
        'Lubna Ferdous',
        '+8801719887766',
        'Gulshan',
        4300,
        'Just checking prices for a school project',
      ),
      status: 'Rejected',
      reason: 'NotInterested',
    ),
  ];
}

Map<String, dynamic> _answer(String label, String labelBn, String value) => {
  'Name': label,
  'NameBn': labelBn,
  'Value': value,
};
