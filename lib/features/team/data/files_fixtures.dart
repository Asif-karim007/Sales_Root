import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/data/team_fixtures.dart';

const int priceListsFolder = 1;
const int brochuresFolder = 2;
const int agreementsFolder = 3;
const int photosFolder = 4;

List<Map<String, dynamic>> folderFixtures(SeedGraph graph) => const [
  {'Id': priceListsFolder, 'Name': 'Price lists', 'NameBn': 'দামের তালিকা'},
  {'Id': brochuresFolder, 'Name': 'Brochures', 'NameBn': 'ব্রোশিওর'},
  {'Id': agreementsFolder, 'Name': 'Agreements', 'NameBn': 'চুক্তি'},
  {
    'Id': photosFolder,
    'Name': 'Site photos',
    'NameBn': 'সাইটের ছবি',
    'IsPhotos': true,
  },
];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

List<Map<String, dynamic>> fileFixtures(SeedGraph graph) {
  final owner = ownerIdOf(graph);
  final lead = graph.members
      .firstWhere(
        (m) => m.role == WorkspaceRole.teamLead,
        orElse: () => graph.member(owner),
      )
      .id;
  final now = graph.anchor;
  String month(int back) {
    final date = DateTime(now.year, now.month - back);
    return '${_months[date.month - 1]}_${date.year}';
  }

  final random = graph.random('team-files');
  final leadIds = graph.leads.take(3).map((l) => l.id).toList();
  var id = 0;
  Map<String, dynamic> file(
    String name,
    int folder,
    int sizeBytes,
    int by,
    int daysAgo, {
    List<(int, int, String?)> history = const [],
    String visibleTo = 'All',
    List<int> leads = const [],
  }) {
    id++;
    final at = graph.daysAgo(daysAgo, hour: 9, minute: 10);
    final versions = [
      (history.length + 1, daysAgo, by, null as String?),
      for (var i = 0; i < history.length; i++)
        (history.length - i, history[i].$1, history[i].$2, history[i].$3),
    ];
    return {
      'Id': id,
      'Name': name,
      'FolderId': folder,
      'SizeBytes': sizeBytes,
      'UploadedById': versions.last.$3,
      'UploadedAt': jsonUtc(graph.daysAgo(versions.last.$2, hour: 11)),
      'UpdatedAt': jsonUtc(at),
      'Version': versions.length,
      'Versions': [
        for (final (version, days, author, note) in versions)
          {
            'Version': version,
            'At': jsonUtc(graph.daysAgo(days, hour: 9, minute: 10)),
            'ById': author,
            'Note': ?note,
          },
      ],
      'VisibleTo': visibleTo,
      'LinkedLeadIds': leads,
    };
  }

  final files = [
    file(
      'Price_list_${month(0)}.pdf',
      priceListsFolder,
      1250000,
      lead,
      0,
      history: [(19, lead, 'dealer prices updated'), (33, owner, null)],
      leads: leadIds,
    ),
    file(
      'Dealer_price_list_${month(1)}.pdf',
      priceListsFolder,
      980000,
      owner,
      34,
    ),
    file('Price_list_${month(1)}.pdf', priceListsFolder, 1180000, lead, 36),
    file(
      'Installation_rates_${now.year}.xlsx',
      priceListsFolder,
      86000,
      owner,
      50,
    ),
    file('Solar_brochure_${now.year}.pdf', brochuresFolder, 4800000, owner, 12),
    file('Hybrid_inverter_datasheet.pdf', brochuresFolder, 2300000, lead, 20),
    file('Lithium_battery_10kWh_spec.pdf', brochuresFolder, 1700000, lead, 27),
    file('Street_light_catalogue.pdf', brochuresFolder, 3600000, owner, 45),
    file('Company_profile.pdf', brochuresFolder, 5200000, owner, 80),
    file(
      'Dealer_agreement_template.docx',
      agreementsFolder,
      320000,
      owner,
      30,
      visibleTo: 'TeamLeads',
    ),
    file(
      'AMC_contract_template.docx',
      agreementsFolder,
      210000,
      owner,
      44,
      visibleTo: 'TeamLeads',
    ),
    file('Net_metering_application.pdf', agreementsFolder, 640000, lead, 15),
    file(
      'NDA_template.docx',
      agreementsFolder,
      95000,
      owner,
      70,
      visibleTo: 'TeamLeads',
    ),
  ];
  final people = graph.members.map((m) => m.id).toList();
  for (var i = 0; i < 138; i++) {
    final siteLead = graph.leads.isEmpty
        ? null
        : graph.leads[(i ~/ 3) % graph.leads.length];
    final company = siteLead == null
        ? 'Site'
        : graph.company(siteLead.companyId).name.replaceAll(' ', '_');
    files.add(
      file(
        '${company}_site_${(i % 3) + 1}.jpg',
        photosFolder,
        5000000 + random.nextInt(6000000),
        people[random.nextInt(people.length)],
        1 + i * 120 ~/ 138,
        leads: [?siteLead?.id],
      ),
    );
  }
  return files;
}
