import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

/// The technician new tickets go to: Arif when he is in the workspace.
SeedMember technicianOf(SeedGraph graph) =>
    graph.members.where((m) => m.name.startsWith('Arif')).firstOrNull ??
    graph.me;

String ticketCode(int id) => 'T-${(80 + id).toString().padLeft(4, '0')}';

Map<String, dynamic> customerRow(SeedGraph graph, SeedCompany company) => {
  'Id': company.id,
  'Name': company.name,
  'Area': company.area.name,
  'AreaBn': company.area.nameBn,
  'Phone': company.phone,
  'LeadId': graph.leads.where((l) => l.companyId == company.id).firstOrNull?.id,
}..removeWhere((_, value) => value == null);

Map<String, dynamic> ticketRow({
  required SeedGraph graph,
  required int id,
  required SeedCompany customer,
  required String title,
  required TicketIssue issue,
  required TicketPriority priority,
  required TicketStatus status,
  required DateTime openedAt,
  required String source,
  SeedProduct? product,
  List<String> photos = const [],
  List<Map<String, dynamic>> messages = const [],
}) {
  final customerFields = customerRow(graph, customer);
  return {
    'Id': id,
    'Code': ticketCode(id),
    'Title': title,
    'CustomerId': customer.id,
    'CustomerName': customer.name,
    'LeadId': customerFields['LeadId'],
    'IssueType': issue.wire,
    'Priority': priority.wire,
    'Status': status.wire,
    'ProductId': product?.id,
    'ProductName': product?.name,
    ...personFields('AssigneeName', technicianOf(graph)),
    'OpenedAt': jsonUtc(openedAt),
    'DueAt': jsonUtc(openedAt.add(Duration(hours: priority.slaHours))),
    'Source': source,
    'Photos': photos,
    'Messages': messages,
    'CreatedBy': SeedGraph.meId,
  }..removeWhere((_, value) => value == null);
}

Map<String, dynamic> ticketMessage(
  String text, {
  required DateTime at,
  required bool fromTeam,
  String? author,
}) => {
  'Text': text,
  'FromTeam': fromTeam,
  'AuthorName': author,
  'At': jsonUtc(at),
}..removeWhere((_, value) => value == null);

List<Map<String, dynamic>> ticketFixtures(SeedGraph graph) {
  final technician = technicianOf(graph).name.split(' ').first;
  final rows = <Map<String, dynamic>>[];
  for (var i = 0; i < _seeds.length; i++) {
    final seed = _seeds[i];
    final customer = graph.companies[(i * 7) % graph.companies.length];
    final opened = graph.daysAgo(seed.daysAgo, hour: 11, minute: 20);
    final productId = seed.productId;
    final reply = seed.reply;
    rows.add(
      ticketRow(
        graph: graph,
        id: i + 1,
        customer: customer,
        title: seed.title,
        issue: seed.issue,
        priority: seed.priority,
        status: seed.status,
        openedAt: opened,
        source: seed.source,
        product: productId == null ? null : graph.product(productId),
        photos: seed.photo ? ['ticket_${i + 1}_1.jpg'] : const [],
        messages: [
          ticketMessage(
            seed.complaint,
            at: opened,
            fromTeam: false,
            author: customer.name,
          ),
          if (reply != null)
            ticketMessage(
              reply.replaceAll('{tech}', technician),
              at: opened.add(const Duration(minutes: 12)),
              fromTeam: true,
              author: graph.me.name,
            ),
        ],
      ),
    );
  }
  return rows.reversed.toList();
}

class _TicketSeed {
  const _TicketSeed(
    this.title,
    this.complaint,
    this.issue,
    this.priority,
    this.status,
    this.daysAgo, {
    this.reply,
    this.productId,
    this.source = 'FieldVisit',
    this.photo = false,
  });

  final String title;
  final String complaint;
  final TicketIssue issue;
  final TicketPriority priority;
  final TicketStatus status;
  final int daysAgo;
  final String? reply;
  final int? productId;
  final String source;
  final bool photo;
}

const List<_TicketSeed> _seeds = [
  _TicketSeed(
    'Pump not starting in the morning',
    'সকালে সোলার পাম্প চালু হচ্ছে না, দুপুরে ঠিক থাকে।',
    TicketIssue.problem,
    TicketPriority.medium,
    TicketStatus.resolved,
    40,
    reply: 'Controller setting fixed on site by {tech}.',
    productId: 28,
    source: 'Phone',
  ),
  _TicketSeed(
    'Invoice amount mismatch',
    'Invoice shows ৳ 2,48,000 but the quotation was ৳ 2,40,000.',
    TicketIssue.billing,
    TicketPriority.medium,
    TicketStatus.resolved,
    26,
    reply: 'Corrected invoice sent by email. Sorry for the confusion.',
    source: 'WhatsApp',
  ),
  _TicketSeed(
    'Street light dim after 2 am',
    'Gate-er street light raat 2 tar por kom alo dey.',
    TicketIssue.warranty,
    TicketPriority.low,
    TicketStatus.onHold,
    15,
    reply: 'Replacement battery ordered, waiting for stock.',
    productId: 25,
    photo: true,
  ),
  _TicketSeed(
    'Rooftop installation schedule',
    'We want the 5 kW installation done before the Puja holidays.',
    TicketIssue.installation,
    TicketPriority.low,
    TicketStatus.open,
    6,
    productId: 39,
  ),
  _TicketSeed(
    'Battery not holding charge',
    'Lithium battery 2 ghontar beshi backup dey na, warranty-te ache.',
    TicketIssue.warranty,
    TicketPriority.high,
    TicketStatus.inProgress,
    3,
    reply: 'Logs downloaded, {tech} will test the cells tomorrow.',
    productId: 11,
    photo: true,
  ),
  _TicketSeed(
    'Monitoring app shows no data',
    'Wi-Fi dongle-er light jole, kintu app-e kichu dekhay na.',
    TicketIssue.other,
    TicketPriority.medium,
    TicketStatus.open,
    1,
    productId: 24,
    source: 'WhatsApp',
  ),
  _TicketSeed(
    'Inverter beeping',
    'Inverter beeps every 5 minutes, red light on.',
    TicketIssue.problem,
    TicketPriority.high,
    TicketStatus.inProgress,
    0,
    reply: 'Checking the battery cable. {tech} will visit today at 15:00.',
    productId: 7,
    source: 'WhatsApp',
    photo: true,
  ),
];
